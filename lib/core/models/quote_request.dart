import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus {
  pending,
  reviewing,
  quoted,
  accepted,
  rejected,
  inProduction,
  delivered,
  cancelled,
}

enum RequestType { gift, event }

extension RequestStatusX on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.pending: return 'Attente devis';
      case RequestStatus.reviewing: return 'En revue';
      case RequestStatus.quoted: return 'Devis reçu';
      case RequestStatus.accepted: return 'Accepté';
      case RequestStatus.rejected: return 'Refusé';
      case RequestStatus.inProduction: return 'En production';
      case RequestStatus.delivered: return 'Livré';
      case RequestStatus.cancelled: return 'Annulé';
    }
  }
}

class QuoteRequest {
  final String id;
  final String customerId;
  final String customerName;
  final String? companyName; // Nullable for B2C
  final RequestType type;
  final RequestStatus status;
  final Map<String, dynamic> details;
  final List<String> attachmentUrls;
  final double? supplierPrice;
  final double? quotedPrice;
  final String? adminNote;
  final String? customerNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QuoteRequest({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.companyName,
    required this.type,
    required this.status,
    required this.details,
    required this.attachmentUrls,
    this.supplierPrice,
    this.quotedPrice,
    this.adminNote,
    this.customerNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuoteRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuoteRequest(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      companyName: data['companyName'] ?? '',
      type: data['type'] == 'event' ? RequestType.event : RequestType.gift,
      status: RequestStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => RequestStatus.pending,
      ),
      details: Map<String, dynamic>.from(data['details'] ?? {}),
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      supplierPrice: (data['supplierPrice'] as num?)?.toDouble(),
      quotedPrice: (data['quotedPrice'] as num?)?.toDouble(),
      adminNote: data['adminNote'],
      customerNote: data['customerNote'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'customerId': customerId,
    'customerName': customerName,
    'companyName': companyName, // Map handles null
    'type': type.name,
    'status': status.name,
    'details': details,
    'attachmentUrls': attachmentUrls,
    'supplierPrice': supplierPrice,
    'quotedPrice': quotedPrice,
    'adminNote': adminNote,
    'customerNote': customerNote,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  QuoteRequest copyWith({
    String? id,
    RequestStatus? status,
    double? supplierPrice,
    double? quotedPrice,
    String? adminNote,
    String? customerNote,
    List<String>? attachmentUrls,
  }) => QuoteRequest(
    id: id ?? this.id,
    customerId: customerId,
    customerName: customerName,
    companyName: companyName,
    type: type,
    status: status ?? this.status,
    details: details,
    attachmentUrls: attachmentUrls ?? this.attachmentUrls,
    supplierPrice: supplierPrice ?? this.supplierPrice,
    quotedPrice: quotedPrice ?? this.quotedPrice,
    adminNote: adminNote ?? this.adminNote,
    customerNote: customerNote ?? this.customerNote,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );

  String get inferredClientType {
    final raw = details['clientType']?.toString().toLowerCase();
    if (raw == 'b2b' || raw == 'b2c') return raw!;

    final hasCompany = (companyName ?? '').trim().isNotEmpty;
    return hasCompany ? 'b2b' : 'b2c';
  }
}
