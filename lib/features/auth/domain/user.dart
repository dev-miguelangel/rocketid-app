import 'package:freezed_annotation/freezed_annotation.dart';
import 'profile.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const User._();

  const factory User({
    required String id,
    required String email,
    Profile? profile,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}