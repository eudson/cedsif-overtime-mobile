import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:cedsif_overtime_mobile/features/overtime/presentation/providers/overtime_provider.dart';

class _MockOvertimeRepository extends Mock implements OvertimeRepository {}

void main() {
  late _MockOvertimeRepository repository;
  late DateTime now;
  late ProviderContainer container;

  setUp(() {
    repository = _MockOvertimeRepository();
    now = DateTime(2026, 8, 13, 10);
    container = ProviderContainer(
      overrides: [
        overtimeRepositoryProvider.overrideWithValue(repository),
        overtimeClockProvider.overrideWithValue(() => now),
      ],
    );
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

  test('start persists one session and enters running state', () async {
    final started = OvertimeSession(
      id: 'new',
      startedAt: now,
      status: OvertimeSessionStatus.active,
    );
    when(
      () => repository.start(now),
    ).thenAnswer((_) async => Right<Failure, OvertimeSession>(started));
    when(repository.load).thenAnswer(
      (_) async =>
          const Right<Failure, OvertimeSnapshot>(OvertimeSnapshot(history: [])),
    );
    await container.read(overtimeProvider.notifier).load();

    await container.read(overtimeProvider.notifier).start();

    expect(container.read(overtimeProvider).activeSession, started);
    expect(container.read(overtimeProvider).isSaving, isFalse);
    verify(() => repository.start(now)).called(1);
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
      when(() => repository.start(now)).thenAnswer(
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

    verifyNever(() => repository.start(any()));
    pendingLoad.complete(
      const Right<Failure, OvertimeSnapshot>(OvertimeSnapshot(history: [])),
    );
    await loading;
    expect(container.read(overtimeProvider).isLoaded, isTrue);
  });
}
