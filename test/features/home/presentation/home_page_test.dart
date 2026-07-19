import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:cedsif_overtime_mobile/core/error/failures.dart';
import 'package:cedsif_overtime_mobile/features/home/domain/entities/home_content.dart';
import 'package:cedsif_overtime_mobile/features/home/domain/repositories/home_repository.dart';
import 'package:cedsif_overtime_mobile/features/home/presentation/pages/home_page.dart';
import 'package:cedsif_overtime_mobile/features/home/presentation/providers/home_provider.dart';

class _TrackingTestBinding extends AutomatedTestWidgetsFlutterBinding {
  int defaultPostFrameCallbackCount = 0;

  @override
  void addPostFrameCallback(
    FrameCallback callback, {
    String debugLabel = 'callback',
  }) {
    if (debugLabel == 'callback') {
      defaultPostFrameCallbackCount += 1;
    }
    super.addPostFrameCallback(callback, debugLabel: debugLabel);
  }
}

class _PendingHomeRepository implements HomeRepository {
  final _result = Completer<Either<Failure, HomeContent>>();

  int loadCount = 0;

  @override
  Future<Either<Failure, HomeContent>> getContent() {
    loadCount += 1;
    return _result.future;
  }
}

void main() {
  final binding = _TrackingTestBinding();

  testWidgets('loads once from the widget lifecycle across rebuilds', (
    tester,
  ) async {
    final repository = _PendingHomeRepository();
    Widget buildApp() => ProviderScope(
      overrides: [homeRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: HomePage()),
    );

    binding.defaultPostFrameCallbackCount = 0;
    await tester.pumpWidget(buildApp());
    expect(repository.loadCount, 1);
    expect(binding.defaultPostFrameCallbackCount, 0);

    await tester.pumpWidget(buildApp());
    expect(repository.loadCount, 1);
    expect(binding.defaultPostFrameCallbackCount, 0);
  });
}
