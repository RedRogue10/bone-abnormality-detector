class EmergencyContact {
  final String name;
  final String contactNumber;
  final String relationship;

  EmergencyContact({
    required this.name,
    required this.contactNumber,
    required this.relationship,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'contactNumber': contactNumber,
      'relationship': relationship,
    };
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'],
      contactNumber: map['contactNumber'],
      relationship: map['relationship'],
    );
  }
}
