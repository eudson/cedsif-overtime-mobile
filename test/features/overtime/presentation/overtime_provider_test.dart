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

  test('stop creates a pending history snapshot and returns to idle', () async {
    final active = OvertimeSession(
      id: 'active',
      startedAt: DateTime(2026, 8, 13, 9),
      status: OvertimeSessionStatus.active,
    );
    final completed = active.completeAt(now);
    when(repository.load).thenAnswer(
      (_) async => Right<Failure, OvertimeSnapshot>(
        OvertimeSnapshot(activeSession: active, history: const []),
      ),
    );
    when(() => repository.stop(now)).thenAnswer(
      (_) async => Right<Failure, OvertimeSnapshot>(
        OvertimeSnapshot(history: [completed]),
      ),
    );
    final notifier = container.read(overtimeProvider.notifier);
    await notifier.load();

    await notifier.stop();

    final state = container.read(overtimeProvider);
    expect(state.activeSession, isNull);
    expect(state.history.single, completed);
    expect(state.history.single.status, OvertimeSessionStatus.pending);
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
