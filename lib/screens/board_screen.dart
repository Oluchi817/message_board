
import 'package:flutter/material.dart';

import '../models/message.dart';
import '../services/auth_service.dart';
import '../services/board_service.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final AuthService _authService = AuthService();
  final BoardService _boardService = BoardService();

  final TextEditingController _messageController =
      TextEditingController();

  bool _isPosting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _postMessage() async {
  if (_isPosting) return;

  final text = _messageController.text.trim();

  if (text.isEmpty) return;

  setState(() {
    _isPosting = true;
  });

  try {
    final user = _authService.currentUser;

    if (user == null) return;

    await _boardService.createMessage(
      text: text,
      authorUid: user.uid,
      authorName: user.email ?? 'User',
    );

    _messageController.clear();
  } catch (e) {
    debugPrint('POST ERROR: $e');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not post your message.'),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isPosting = false;
      });
    }
  }
}

  Future<void> _editMessage(Message message) async {
    final controller = TextEditingController(text: message.text);

    final newText = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Message'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Enter your message',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newText == null || newText.isEmpty) {
      return;
    }

    try {
      await _boardService.updateMessage(
        messageId: message.id,
        newText: newText,
      );

      if (mounted) {
        _showMessage('Message updated.');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Could not update this message.');
      }
    }
  }

  Future<void> _deleteMessage(Message message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Message?'),
          content: const Text(
            'Are you sure you want to delete this message?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _boardService.deleteMessage(message.id);

      if (mounted) {
        _showMessage('Message deleted.');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Could not delete this message.');
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
    } catch (e) {
      _showMessage('Unable to log out. Please try again.');
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Just now';
    }

    return '${date.month}/${date.day}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMessageCard(Message message, String currentUid) {
    final isOwner = message.authorUid == currentUid;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(message.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwner) ...[
                  IconButton(
                    tooltip: 'Edit message',
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editMessage(message),
                  ),
                  IconButton(
                    tooltip: 'Delete message',
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    onPressed: () => _deleteMessage(message),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message.text,
              style: const TextStyle(fontSize: 16),
            ),
            if (message.editedAt != null) ...[
              const SizedBox(height: 6),
              const Text(
                'Edited',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in again.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Board'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Write a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isPosting ? null : _postMessage,
                  icon: _isPosting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _boardService.getMessages(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Unable to load messages. Check your connection '
                      'or Firestore permissions.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 55,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No messages yet.',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text('Be the first to post!'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageCard(
                      messages[index],
                      user.uid,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
