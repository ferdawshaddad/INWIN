import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';

final messageServiceProvider = Provider<MessageService>((ref) => MessageService());

final requestMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, requestId) {
  return ref.watch(messageServiceProvider).watchMessages(requestId);
});

class MessageService {
  final _db = FirebaseFirestore.instance;

  CollectionReference _col(String requestId) =>
      _db.collection('requests').doc(requestId).collection('messages');

  Stream<List<ChatMessage>> watchMessages(String requestId) {
    return _col(requestId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(ChatMessage.fromFirestore).toList());
  }

  Future<void> sendMessage({
    required String requestId,
    required String senderId,
    required String senderName,
    required bool isAdmin,
    required String text,
    List<String> attachments = const [],
  }) {
    return _col(requestId).add({
      'requestId': requestId,
      'senderId': senderId,
      'senderName': senderName,
      'isAdmin': isAdmin,
      'text': text,
      'attachments': attachments,
      'createdAt': Timestamp.now(),
      'isRead': false,
    });
  }

  Future<void> markAsRead(String requestId, String messageId) =>
      _col(requestId).doc(messageId).update({'isRead': true});
}
