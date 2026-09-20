import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quote_request.dart';

final requestServiceProvider = Provider<RequestService>((ref) => RequestService());

final quoteRequestProvider = StreamProvider.family<QuoteRequest?, String>((ref, id) {
  return ref.watch(requestServiceProvider).watchRequest(id);
});

final allRequestsProvider = StreamProvider<List<QuoteRequest>>((ref) {
  return ref.watch(requestServiceProvider).watchAllRequests();
});

final customerRequestsProvider = StreamProvider.family<List<QuoteRequest>, String>((ref, uid) {
  return ref.watch(requestServiceProvider).watchCustomerRequests(uid);
});

class RequestService {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('requests');

  Future<QuoteRequest> createRequest(QuoteRequest req) async {
    final docRef = await _col.add(req.toMap());
    return req.copyWith(id: docRef.id);
  }

  Stream<List<QuoteRequest>> watchCustomerRequests(String customerId) {
    // TEMPORARY: Removed .orderBy to check if the index is the problem
    return _col
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((s) {
          final list = s.docs.map(QuoteRequest.fromFirestore).toList();
          // Sort manually in memory for now to avoid needing an index immediately
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<QuoteRequest>> watchAllRequests({RequestStatus? status}) {
    Query q = _col.orderBy('createdAt', descending: true);
    if (status != null) q = q.where('status', isEqualTo: status.name);
    return q.snapshots().map((s) => s.docs.map(QuoteRequest.fromFirestore).toList());
  }

  Stream<QuoteRequest?> watchRequest(String id) {
    return _col.doc(id).snapshots().map(
      (doc) => doc.exists ? QuoteRequest.fromFirestore(doc) : null,
    );
  }

  // Admin: update request status and quote price
  Future<void> sendQuote({
    required String requestId,
    required double supplierPrice,
    required double quotedPrice,
    String? adminNote,
  }) => _col.doc(requestId).update({
    'status': RequestStatus.quoted.name,
    'supplierPrice': supplierPrice,
    'quotedPrice': quotedPrice,
    'adminNote': adminNote,
    'updatedAt': Timestamp.now(),
  });

  // Customer: accept or reject the quote
  Future<void> respondToQuote({
    required String requestId,
    required bool accepted,
    String? note,
  }) => _col.doc(requestId).update({
    'status': accepted ? RequestStatus.accepted.name : RequestStatus.rejected.name,
    'customerNote': note,
    'updatedAt': Timestamp.now(),
  });

  Future<void> updateStatus(String requestId, RequestStatus status) =>
      _col.doc(requestId).update({
        'status': status.name,
        'updatedAt': Timestamp.now(),
      });

  Future<void> addAttachment(String requestId, String url) =>
      _col.doc(requestId).update({
        'attachmentUrls': FieldValue.arrayUnion([url]),
        'updatedAt': Timestamp.now(),
      });
}
