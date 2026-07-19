import 'package:equatable/equatable.dart';

class HomeContent extends Equatable {
  const HomeContent({required this.translationKey});

  final String translationKey;

  @override
  List<Object?> get props => [translationKey];
}
