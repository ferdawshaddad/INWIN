import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { customer, admin }

/// B2B = entreprise (gifts + events pro)
/// B2C = particulier (personal events only)
enum ClientType {
  b2b,
  b2c;

  String get label => this == ClientType.b2b ? 'Entreprise' : 'Particulier';
  bool get isB2B => this == ClientType.b2b;
  bool get isB2C => this == ClientType.b2c;
}

class AppUser {
  final String uid;
  final String fullName;
  final String? companyName; // null for B2C
  final String email;
  final String phone;
  final UserRole role;
  final ClientType clientType;
  final String? photoUrl;
  final String? fcmToken;
  final DateTime createdAt;

  bool get isB2B => clientType.isB2B;
  bool get isB2C => clientType.isB2C;

  const AppUser({
    required this.uid,
    required this.fullName,
    this.companyName,
    required this.email,
    required this.phone,
    required this.role,
    required this.clientType,
    this.photoUrl,
    this.fcmToken,
    required this.createdAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>?;
    if (d == null) throw Exception("User data null");
    
    return AppUser(
      uid: doc.id,
      fullName: d['fullName'] ?? '',
      companyName: d['companyName'],
      email: d['email'] ?? '',
      phone: d['phone'] ?? '',
      role: d['role'] == 'admin' ? UserRole.admin : UserRole.customer,
      clientType: d['clientType'] == 'b2c' ? ClientType.b2c : ClientType.b2b,
      photoUrl: d['photoUrl'],
      fcmToken: d['fcmToken'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'fullName': fullName,
    if (companyName != null) 'companyName': companyName,
    'email': email,
    'phone': phone,
    'role': role.name,
    'clientType': clientType.name,
    'photoUrl': photoUrl,
    'fcmToken': fcmToken,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  AppUser copyWith({
    String? fullName,
    String? companyName,
    String? phone,
    String? photoUrl,
    String? fcmToken,
  }) =>
      AppUser(
        uid: uid,
        fullName: fullName ?? this.fullName,
        companyName: companyName ?? this.companyName,
        email: email,
        phone: phone ?? this.phone,
        role: role,
        clientType: clientType,
        photoUrl: photoUrl ?? this.photoUrl,
        fcmToken: fcmToken ?? this.fcmToken,
        createdAt: createdAt,
      );
}
