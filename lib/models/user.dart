import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;

  final String firstName;
  final String lastName;

  final String email;

  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  // ------------------- FROM FIRESTORE ----------------------
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ------------------- TO FIRESTORE ----------------------
  Map<String, dynamic> toMap({bool isUpdate = false}) {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      if (!isUpdate) 'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // ------------------- COPY WITH ----------------------
  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ------------------- FULL NAME ----------------------
  String get fullName {
    return "$firstName $lastName";
  }
}
