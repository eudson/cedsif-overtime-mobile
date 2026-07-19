import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:cedsif_overtime_mobile/features/home/data/datasources/home_local_datasource.dart';
import 'package:cedsif_overtime_mobile/features/home/data/repositories/home_repository_impl.dart';
import 'package:cedsif_overtime_mobile/features/home/domain/entities/home_content.dart';
import 'package:cedsif_overtime_mobile/features/home/domain/repositories/home_repository.dart';
import 'package:cedsif_overtime_mobile/features/home/domain/usecases/get_home_content_usecase.dart';

part 'home_provider.freezed.dart';

@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState({
    @Default(false) bool isLoading,
    HomeContent? content,
    String? errorKey,
  }) = _HomeState;
}

final homeDataSourceProvider = Provider<HomeLocalDataSource>(
  (ref) => const HomeLocalDataSource(),
);

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepositoryImpl(ref.watch(homeDataSourceProvider)),
);

final homeUseCaseProvider = Provider<GetHomeContentUseCase>(
  (ref) => GetHomeContentUseCase(ref.watch(homeRepositoryProvider)),
);

class HomeNotifier extends Notifier<HomeState> {
  @override
  HomeState build() => const HomeState();

  Future<void> load() async {
    state = const HomeState(isLoading: true);
    final result = await ref.read(homeUseCaseProvider)();
    result.fold(
      (failure) => state = HomeState(errorKey: failure.message),
      (content) => state = HomeState(content: content),
    );
  }
}

final homeNotifierProvider = NotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);
