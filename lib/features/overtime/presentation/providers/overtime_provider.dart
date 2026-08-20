import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cedsif_overtime_mobile/core/config/providers.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/datasources/location_data_source.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/datasources/overtime_local_datasource.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/datasources/overtime_remote_datasource.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/repositories/location_repository_impl.dart';
import 'package:cedsif_overtime_mobile/features/overtime/data/repositories/overtime_repository_impl.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/repositories/location_repository.dart';
import 'package:cedsif_overtime_mobile/features/overtime/domain/repositories/overtime_repository.dart';

typedef OvertimeClock = DateTime Function();

final overtimeClockProvider = Provider<OvertimeClock>((ref) => DateTime.now);

final overtimeLocalDataSourceProvider = Provider<OvertimeLocalDataSource>(
  (ref) => OvertimeLocalDataSource(ref.watch(overtimeBoxProvider)),
);

final overtimeRemoteDataSourceProvider = Provider<OvertimeRemoteDataSource>(
  (ref) => DioOvertimeRemoteDataSource(ref.watch(dioProvider)),
);

final locationPlatformProvider = Provider<LocationPlatform>(
  (ref) => const PluginLocationPlatform(),
);

final locationDataSourceProvider = Provider<LocationDataSource>(
  (ref) => ForegroundLocationDataSource(ref.watch(locationPlatformProvider)),
);

final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => LocationRepositoryImpl(ref.watch(locationDataSourceProvider)),
);

final overtimeRepositoryProvider = Provider<OvertimeRepository>(
  (ref) => OvertimeRepositoryImpl(ref.watch(overtimeLocalDataSourceProvider)),
);

class OvertimeState {
  const OvertimeState({
    this.isLoaded = false,
    this.isSaving = false,
    this.activeSession,
    this.history = const [],
    this.now,
    this.errorKey,
  });

  final bool isLoaded;
  final bool isSaving;
  final OvertimeSession? activeSession;
  final List<OvertimeSession> history;
  final DateTime? now;
  final String? errorKey;

  bool get isRunning => activeSession?.status == OvertimeSessionStatus.active;

  bool get isReviewing =>
      activeSession?.status == OvertimeSessionStatus.reviewing;

  Duration get elapsed {
    final active = activeSession;
    if (active == null) {
      return Duration.zero;
    }
    return active.durationAt(now ?? active.startedAt);
  }

  OvertimeState copyWith({
    bool? isLoaded,
    bool? isSaving,
    Object? activeSession = _unchanged,
    List<OvertimeSession>? history,
    DateTime? now,
    Object? errorKey = _unchanged,
  }) => OvertimeState(
    isLoaded: isLoaded ?? this.isLoaded,
    isSaving: isSaving ?? this.isSaving,
    activeSession: identical(activeSession, _unchanged)
        ? this.activeSession
        : activeSession as OvertimeSession?,
    history: history ?? this.history,
    now: now ?? this.now,
    errorKey: identical(errorKey, _unchanged)
        ? this.errorKey
        : errorKey as String?,
  );
}

const _unchanged = Object();

class OvertimeNotifier extends Notifier<OvertimeState> {
  Timer? _ticker;

  @override
  OvertimeState build() {
    ref.onDispose(() => _ticker?.cancel());
    return const OvertimeState();
  }

  Future<void> load() async {
    final result = await ref.read(overtimeRepositoryProvider).load();
    result.fold(
      (failure) =>
          state = state.copyWith(isLoaded: true, errorKey: failure.message),
      (snapshot) {
        state = OvertimeState(
          isLoaded: true,
          activeSession: snapshot.activeSession,
          history: snapshot.history,
          now: ref.read(overtimeClockProvider)(),
        );
        if (snapshot.activeSession?.status == OvertimeSessionStatus.active) {
          _startTicker();
        }
      },
    );
  }

  Future<void> start() async {
    if (!state.isLoaded || state.isSaving || state.activeSession != null) {
      return;
    }
    final now = ref.read(overtimeClockProvider)();
    state = state.copyWith(isSaving: true, errorKey: null, now: now);
    final result = await ref.read(overtimeRepositoryProvider).start(now);
    result.fold(
      (failure) =>
          state = state.copyWith(isSaving: false, errorKey: failure.message),
      (session) {
        state = state.copyWith(
          isLoaded: true,
          isSaving: false,
          activeSession: session,
          now: now,
        );
        _startTicker();
      },
    );
  }

  Future<void> pause() async {
    if (state.isSaving || !state.isRunning) {
      return;
    }
    final now = ref.read(overtimeClockProvider)();
    state = state.copyWith(isSaving: true, errorKey: null, now: now);
    final result = await ref.read(overtimeRepositoryProvider).pause(now);
    result.fold(
      (failure) =>
          state = state.copyWith(isSaving: false, errorKey: failure.message),
      (session) {
        _ticker?.cancel();
        state = state.copyWith(
          isSaving: false,
          activeSession: session,
          now: now,
        );
      },
    );
  }

  Future<void> resume() async {
    if (state.isSaving || !state.isReviewing) {
      return;
    }
    final now = ref.read(overtimeClockProvider)();
    state = state.copyWith(isSaving: true, errorKey: null, now: now);
    final result = await ref.read(overtimeRepositoryProvider).resume(now);
    result.fold(
      (failure) =>
          state = state.copyWith(isSaving: false, errorKey: failure.message),
      (session) {
        state = state.copyWith(
          isSaving: false,
          activeSession: session,
          now: now,
        );
        _startTicker();
      },
    );
  }

  Future<void> submit() async {
    if (state.isSaving || !state.isReviewing) {
      return;
    }
    state = state.copyWith(isSaving: true, errorKey: null);
    final result = await ref.read(overtimeRepositoryProvider).submit();
    result.fold(
      (failure) =>
          state = state.copyWith(isSaving: false, errorKey: failure.message),
      (snapshot) {
        _ticker?.cancel();
        state = OvertimeState(
          isLoaded: true,
          history: snapshot.history,
          now: state.now,
        );
      },
    );
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(now: ref.read(overtimeClockProvider)());
    });
  }
}

final overtimeProvider = NotifierProvider<OvertimeNotifier, OvertimeState>(
  OvertimeNotifier.new,
);
