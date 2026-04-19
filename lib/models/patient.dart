import 'package:cloud_firestore/cloud_firestore.dart';
import 'emergency_contact.dart';
import '../widgets/shared/patient_form_shared.dart';

class Patient {
  final String id;

  // Required
  final String firstName;
  final String lastName;
  final String sex;
  final DateTime birthDate;

  // Optional
  final String? middleName;
  final String? contactNumber;
  final String? address;
  final String? email;

  final EmergencyContact? emergencyContact;

  final List<PatientHistoryRecord> historyRecords;

  final DateTime createdAt;
  final DateTime updatedAt;

  Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.sex,
    required this.birthDate,

    this.middleName,
    this.contactNumber,
    this.address,
    this.email,
    this.emergencyContact,
    required this.historyRecords,

    required this.createdAt,
    required this.updatedAt,
  });

  // SAVE TO FIRESTORE
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'sex': sex,

      'birthDate': Timestamp.fromDate(birthDate),

      'contactNumber': contactNumber,
      'address': address,
      'email': email,

      'emergencyContact': emergencyContact?.toMap(),

      'historyRecords': historyRecords.map((r) => r.toMap()).toList(),

      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // READ FROM FIRESTORE
  factory Patient.fromMap(Map<String, dynamic> map, String id) {
    return Patient(
      id: id,

      firstName: map['firstName'],
      middleName: map['middleName'],
      lastName: map['lastName'],
      sex: map['sex'],

      birthDate: (map['birthDate'] as Timestamp).toDate(),

      contactNumber: map['contactNumber'],
      address: map['address'],
      email: map['email'],

      emergencyContact: map['emergencyContact'] != null
          ? EmergencyContact.fromMap(map['emergencyContact'])
          : null,

      historyRecords:
          (map['historyRecords'] as List<dynamic>?)
              ?.map(
                (r) => PatientHistoryRecord.fromMap(r as Map<String, dynamic>),
              )
              .toList() ??
          [],

      createdAt: (map['createdAt'] as Timestamp).toDate(),

      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Getters
  String get fullName {
    final middle = middleName != null ? ' $middleName' : '';
    return '$firstName$middle $lastName';
  }

  String get gender => sex;

  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String get initials {
    final firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }
}
