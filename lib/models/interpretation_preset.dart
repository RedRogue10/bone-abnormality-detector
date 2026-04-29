import 'package:cloud_firestore/cloud_firestore.dart';

class InterpretationPreset {
  final String   id;
  final String   title;
  final String   body;
  final DateTime createdAt;

  const InterpretationPreset({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'title':     title,
    'body':      body,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory InterpretationPreset.fromMap(Map<String, dynamic> map, String id) =>
      InterpretationPreset(
        id:        id,
        title:     map['title']  as String,
        body:      map['body']   as String,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
      );
}
