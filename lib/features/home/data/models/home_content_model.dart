import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:cedsif_overtime_mobile/features/home/domain/entities/home_content.dart';

part 'home_content_model.freezed.dart';
part 'home_content_model.g.dart';

@freezed
abstract class HomeContentModel with _$HomeContentModel {
  const HomeContentModel._();

  const factory HomeContentModel({required String translationKey}) =
      _HomeContentModel;

  factory HomeContentModel.fromJson(Map<String, Object?> json) =>
      _$HomeContentModelFromJson(json);

  factory HomeContentModel.fromEntity(HomeContent entity) =>
      HomeContentModel(translationKey: entity.translationKey);

  HomeContent toEntity() => HomeContent(translationKey: translationKey);
}
