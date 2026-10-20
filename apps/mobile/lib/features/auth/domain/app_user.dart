import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

enum UserRole { adult, child }

/// The Cashe user as the API knows it (`GET /me`).
@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required int id,
    required String displayName,
    required UserRole role,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);
}
