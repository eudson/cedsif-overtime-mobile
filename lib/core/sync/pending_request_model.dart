import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_request_model.freezed.dart';
part 'pending_request_model.g.dart';

@freezed
abstract class PendingRequestModel with _$PendingRequestModel {
  const factory PendingRequestModel({
    required String method,
    required String path,
    required Map<String, String> headers,
    required Object? body,
    required DateTime createdAt,
    required int retryCount,
  }) = _PendingRequestModel;

  factory PendingRequestModel.fromJson(Map<String, Object?> json) =>
      _$PendingRequestModelFromJson(json);
}
