import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/core/auth/session_scope.dart';
import 'package:cedsif_overtime_mobile/features/auth/presentation/providers/login_provider.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/device_location.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/repositories/location_repository.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:cedsif_overtime_mobile/features/overtime/presentation/providers/overtime_provider.dart';

class _MockOvertimeRepository extends Mock implements OvertimeRepository {}

class _MockLocationRepository extends Mock implements LocationRepository {}

void main() {
  late _MockOvertimeRepository repository;
  late _MockLocationRepository locationRepository;
  late DeviceLocation location;
  late DateTime now;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(
      DeviceLocation(
        latitude: 0,
        longitude: 0,
        accuracyMeters: 0,
        capturedAt: DateTime.utc(2026),
      ),
    );
  });

  setUp(() {
    repository = _MockOvertimeRepository();
    locationRepository = _MockLocationRepository();
    now = DateTime(2026, 8, 13, 10);
    location = DeviceLocation(
      latitude: -25.9692,
      longitude: 32.5732,
      accuracyMeters: 5,
      capturedAt: now,
    );
    when(
      locationRepository.current,
    ).thenAnswer((_) async => Right<Failure, DeviceLocation>(location));
    container = ProviderContainer(
      overrides: [
        overtimeRepositoryProvider.overrideWithValue(repository),
        locationRepositoryProvider.overrideWithValue(locationRepository),
        overtimeClockProvider.overrideWithValue(() => now),
      ],
    );
    container.read(facialReferenceProvider.notifier).store('face-1');
    addTearDown(container.dispose);
  });

  test('load restores an active session and derives elapsed time', () async {
    final active = OvertimeSession(
      id: 'active',
      startedAt: DateTime(2026, 8, 13, 8, 24),
      status: OvertimeSessionStatus.active,
    );
    when(repository.load).thenAnswer(
      (_) async => Right<Failure, OvertimeSnapshot>(
        OvertimeSnapshot(activeSession: active, history: const []),
      ),
    );

    await container.read(overtimeProvider.notifier).load();

    final state = container.read(overtimeProvider);
    expect(state.isLoaded, isTrue);
    expect(state.activeSession, active);
    expect(state.elapsed, const Duration(hours: 1, minutes: 36));
  });

  test('clears in-memory overtime state when the session changes', () async {
    final active = OvertimeSession(
      id: 'previous-employee-active',
      startedAt: DateTime(2026, 8, 13, 8),
      status: OvertimeSessionStatus.active,
    );
    when(repository.load).thenAnswer(
      (_) async => Right<Failure, OvertimeSnapshot>(
        OvertimeSnapshot(activeSession: active, history: const []),
      ),
    );
    await container.read(overtimeProvider.notifier).load();

    container.read(sessionEpochProvider.notifier).advance();

    expect(container.read(overtimeProvider).isLoaded, isFalse);
    expect(container.read(overtimeProvider).activeSession, isNull);
    expect(container.read(overtimeProvider).history, isEmpty);
    expect(container.read(facialReferenceProvider), isNull);
  });

  test('start persists one session and enters running state', () async {
    final started = OvertimeSession(
      id: 'new',
      startedAt: now,
      status: OvertimeSessionStatus.active,
    );
    when(
      () => repository.start(
        startedAt: now,
        location: location,
        biometricReference: 'face-1',
      ),
    ).thenAnswer((_) async => Right<Failure, OvertimeSession>(started));
    when(repository.load).thenAnswer(
      (_) async =>
          const Right<Failure, OvertimeSnapshot>(OvertimeSnapshot(history: [])),
    );
    await container.read(overtimeProvider.notifier).load();

    await container.read(overtimeProvider.notifier).start();

    expect(container.read(overtimeProvider).activeSession, started);
    expect(container.read(overtimeProvider).isSaving, isFalse);
    verify(
      () => repository.start(
        startedAt: now,
        location: location,
        biometricReference: 'face-1',
      ),
    ).called(1);
  });

  test('dual-active reconciliation conflict blocks start actions', () async {
    when(repository.load).thenAnswer(
      (_) async => const Left<Failure, OvertimeSnapshot>(
        ValidationFailure('overtime.conflictingActiveSession'),
      ),
    );
    final notifier = container.read(overtimeProvider.notifier);

    await notifier.load();
    await notifier.start();

    final state = container.read(overtimeProvider);
    expect(state.hasBlockingConflict, isTrue);
    expect(state.errorKey, 'overtime.conflictingActiveSession');
    verifyNever(locationRepository.current);
    verifyNever(
      () => repository.start(
        startedAt: any(named: 'startedAt'),
        location: any(named: 'location'),
        biometricReference: any(named: 'biometricReference'),
      ),
    );
  });

  test('pause freezes counting and enters review state', () async {
    final active = OvertimeSession(
      id: 'active',
      startedAt: DateTime(2026, 8, 13, 9),
      status: OvertimeSessionStatus.active,
    );
    final reviewing = active.pauseAt(now);
    when(repository.load).thenAnswer(
      (_) async => Right<Failure, OvertimeSnapshot>(
        OvertimeSnapshot(activeSession: active, history: const []),
      ),
    );
    when(
      () => repository.pause(now),
    ).thenAnswer((_) async => Right<Failure, OvertimeSession>(reviewing));
    final notifier = container.read(overtimeProvider.notifier);
    await notifier.load();

    await notifier.pause();

    now = DateTime(2026, 8, 13, 11);
    final state = container.read(overtimeProvider);
    expect(state.activeSession, reviewing);
    expect(state.isReviewing, isTrue);
    expect(state.elapsed, const Duration(hours: 1));
  });

  test('resume returns to counting while excluding review time', () async {
    final reviewing = OvertimeSession(
      id: 'active',
      startedAt: DateTime(2026, 8, 13, 9),
      endedAt: DateTime(2026, 8, 13, 10),
      status: OvertimeSessionStatus.reviewing,
    );
    final resumedAt = DateTime(2026, 8, 13, 10, 30);
    final resumed = reviewing.resumeAt(resumedAt);
    now = resumedAt;
    when(repository.load).thenAnswer(
      (_) async => Right<Failure, OvertimeSnapshot>(
        OvertimeSnapshot(activeSession: reviewing, history: const []),
      ),
    );
    when(
      () => repository.resume(resumedAt),
    ).thenAnswer((_) async => Right<Failure, OvertimeSession>(resumed));
    final notifier = container.read(overtimeProvider.notifier);
    await notifier.load();

    await notifier.resume();

    final state = container.read(overtimeProvider);
    expect(state.activeSession, resumed);
    expect(state.isRunning, isTrue);
    expect(state.elapsed, const Duration(hours: 1));
  });

  test('submit creates pending history and returns to idle', () async {
    final reviewing = OvertimeSession(
      id: 'active',
      startedAt: DateTime(2026, 8, 13, 9),
      endedAt: now,
      status: OvertimeSessionStatus.reviewing,
    );
    final completed = reviewing.submit();
    when(repository.load).thenAnswer(
      (_) async => Right<Failure, OvertimeSnapshot>(
        OvertimeSnapshot(activeSession: reviewing, history: const []),
      ),
    );
    when(repository.submit).thenAnswer(
      (_) async => Right<Failure, OvertimeSnapshot>(
        OvertimeSnapshot(history: [completed]),
      ),
    );
    final notifier = container.read(overtimeProvider.notifier);
    await notifier.load();

    await notifier.submit();

    final state = container.read(overtimeProvider);
    expect(state.activeSession, isNull);
    expect(state.history, [completed]);
  });

  test(
    'exposes a localized error and retains state on persistence failure',
    () async {
      when(repository.load).thenAnswer(
        (_) async => const Right<Failure, OvertimeSnapshot>(
          OvertimeSnapshot(history: []),
        ),
      );
      when(
        () => repository.start(
          startedAt: now,
          location: location,
          biometricReference: 'face-1',
        ),
      ).thenAnswer(
        (_) async => const Left<Failure, OvertimeSession>(
          CacheFailure('errors.generic'),
        ),
      );

      final notifier = container.read(overtimeProvider.notifier);
      await notifier.load();
      await notifier.start();

      final state = container.read(overtimeProvider);
      expect(state.activeSession, isNull);
      expect(state.errorKey, 'errors.generic');
      expect(state.isSaving, isFalse);
    },
  );

  test('ignores start while the initial cache load is in progress', () async {
    final pendingLoad = Completer<Either<Failure, OvertimeSnapshot>>();
    when(repository.load).thenAnswer((_) => pendingLoad.future);
    final notifier = container.read(overtimeProvider.notifier);

    final loading = notifier.load();
    await notifier.start();

    verifyNever(
      () => repository.start(
        startedAt: any(named: 'startedAt'),
        location: any(named: 'location'),
        biometricReference: any(named: 'biometricReference'),
      ),
    );
    pendingLoad.complete(
      const Right<Failure, OvertimeSnapshot>(OvertimeSnapshot(history: [])),
    );
    await loading;
    expect(container.read(overtimeProvider).isLoaded, isTrue);
  });

  test('requires this-launch facial verification before location', () async {
    container.read(facialReferenceProvider.notifier).clear();
    when(repository.load).thenAnswer(
      (_) async =>
          const Right<Failure, OvertimeSnapshot>(OvertimeSnapshot(history: [])),
    );
    final notifier = container.read(overtimeProvider.notifier);
    await notifier.load();

    await notifier.start();

    expect(container.read(overtimeProvider).errorKey, 'auth.facialRequired');
    verifyNever(locationRepository.current);
  });

  test('surfaces location failure without starting overtime', () async {
    when(locationRepository.current).thenAnswer(
      (_) async => const Left<Failure, DeviceLocation>(
        ValidationFailure('location.permissionDenied'),
      ),
    );
    when(repository.load).thenAnswer(
      (_) async =>
          const Right<Failure, OvertimeSnapshot>(OvertimeSnapshot(history: [])),
    );
    final notifier = container.read(overtimeProvider.notifier);
    await notifier.load();

    await notifier.start();

    expect(
      container.read(overtimeProvider).errorKey,
      'location.permissionDenied',
    );
    verifyNever(
      () => repository.start(
        startedAt: any(named: 'startedAt'),
        location: any(named: 'location'),
        biometricReference: any(named: 'biometricReference'),
      ),
    );
  });
}
