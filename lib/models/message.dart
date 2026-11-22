
import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String text;
  final String authorUid;
  final String authorName;
  final DateTime? createdAt;
  final DateTime? editedAt;

  Message({
    required this.id,
    required this.text,
    required this.authorUid,
    required this.authorName,
    this.createdAt,
    this.editedAt,
  });

  factory Message.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    final createdTimestamp = data['createdAt'] as Timestamp?;
    final editedTimestamp = data['editedAt'] as Timestamp?;

    return Message(
      id: document.id,
      text: data['text'] as String? ?? '',
      authorUid: data['authorUid'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Unknown',
      createdAt: createdTimestamp?.toDate(),
      editedAt: editedTimestamp?.toDate(),
    );
  }
}
