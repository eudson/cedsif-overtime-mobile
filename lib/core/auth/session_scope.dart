import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionEpochNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void advance() => state += 1;
}

final sessionEpochProvider = NotifierProvider<SessionEpochNotifier, int>(
  SessionEpochNotifier.new,
);
