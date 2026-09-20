import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String requestId;
  final String senderId;
  final String senderName;
  final bool isAdmin;
  final String text;
  final List<String> attachments;
  final DateTime createdAt;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.requestId,
    required this.senderId,
    required this.senderName,
    required this.isAdmin,
    required this.text,
    required this.attachments,
    required this.createdAt,
    required this.isRead,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      requestId: data['requestId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
      text: data['text'] ?? '',
      attachments: List<String>.from(data['attachments'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'requestId': requestId,
    'senderId': senderId,
    'senderName': senderName,
    'isAdmin': isAdmin,
    'text': text,
    'attachments': attachments,
    'createdAt': Timestamp.fromDate(createdAt),
    'isRead': isRead,
  };
}
