import 'package:freezed_annotation/freezed_annotation.dart';

part 'ping_outcome.freezed.dart';
part 'ping_outcome.g.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum PingStatus { outsideZone, outsideTimeWindow, dwelling, unlocked, rejected }

@JsonEnum(fieldRename: FieldRename.snake)
enum RejectionReason { mockLocation, lowAccuracy }

/// What the API concluded from one presence ping.
@freezed
abstract class PingOutcome with _$PingOutcome {
  const factory PingOutcome({
    required PingStatus status,
    bool? insideZone,
    bool? inTimeWindow,
    required int dwellProgressSeconds,
    int? dwellRequiredSeconds,
    DateTime? unlockedUntil,
    RejectionReason? reason,
  }) = _PingOutcome;

  factory PingOutcome.fromJson(Map<String, dynamic> json) =>
      _$PingOutcomeFromJson(json);
}

/// One location fix sent to the API, then forgotten.
@freezed
abstract class PingRequest with _$PingRequest {
  const factory PingRequest({
    required double latitude,
    required double longitude,
    required double accuracyM,
    required bool isMocked,
  }) = _PingRequest;

  factory PingRequest.fromJson(Map<String, dynamic> json) =>
      _$PingRequestFromJson(json);
}
