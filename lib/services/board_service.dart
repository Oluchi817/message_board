
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

class BoardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _messages =>
      _firestore.collection('messages');

  // CREATE: Add a new message.
  Future<void> createMessage({
    required String text,
    required String authorUid,
    required String authorName,
  }) async {
    if (text.trim().isEmpty) {
      throw Exception('Message cannot be empty.');
    }

    await _messages.add({
      'text': text.trim(),
      'authorUid': authorUid,
      'authorName': authorName,
      'createdAt': FieldValue.serverTimestamp(),
      'editedAt': null,
    });
  }

  // READ: Listen to messages in real time.
  Stream<List<Message>> getMessages() {
    return _messages
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((document) => Message.fromFirestore(document))
          .toList();
    });
  }

  // UPDATE: Edit an existing message.
  Future<void> updateMessage({
    required String messageId,
    required String newText,
  }) async {
    if (newText.trim().isEmpty) {
      throw Exception('Message cannot be empty.');
    }

    await _messages.doc(messageId).update({
      'text': newText.trim(),
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  // DELETE: Remove one message.
  Future<void> deleteMessage(String messageId) async {
    await _messages.doc(messageId).delete();
  }
}
