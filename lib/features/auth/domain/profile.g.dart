// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProfileImpl _$$ProfileImplFromJson(Map<String, dynamic> json) =>
    _$ProfileImpl(
      id: json['id'] as String,
      birthDate: json['birthDate'] as String?,
      gender: json['gender'] as String?,
      city: json['city'] as String?,
      phone: json['phone'] as String?,
      alias: json['alias'] as String?,
      stringId: json['stringId'] as String?,
      bloodType: json['bloodType'] as String?,
      allergies: (json['allergies'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      conditions: (json['conditions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      medications: (json['medications'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      emergencyContactRelationship:
          json['emergencyContactRelationship'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$$ProfileImplToJson(_$ProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'birthDate': instance.birthDate,
      'gender': instance.gender,
      'city': instance.city,
      'phone': instance.phone,
      'alias': instance.alias,
      'stringId': instance.stringId,
      'bloodType': instance.bloodType,
      'allergies': instance.allergies,
      'conditions': instance.conditions,
      'medications': instance.medications,
      'emergencyContactName': instance.emergencyContactName,
      'emergencyContactPhone': instance.emergencyContactPhone,
      'emergencyContactRelationship': instance.emergencyContactRelationship,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
