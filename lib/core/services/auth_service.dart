import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authServiceProvider).userStream;
});

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<AppUser?> get userStream {
    late final StreamController<AppUser?> controller;
    StreamSubscription<User?>? authSubscription;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
        userDocSubscription;

    Future<void> bindUserDoc(User firebaseUser) async {
      final userDoc = _db.collection('users').doc(firebaseUser.uid);
      final snapshot = await userDoc.get();

      if (!snapshot.exists) {
        await userDoc.set(_buildFallbackUserMap(firebaseUser));
      }

      userDocSubscription = userDoc.snapshots().listen(
        (doc) {
          controller.add(doc.exists ? AppUser.fromFirestore(doc) : null);
        },
        onError: controller.addError,
      );
    }

    controller = StreamController<AppUser?>(
      onListen: () {
        authSubscription = _auth.authStateChanges().listen(
          (firebaseUser) async {
            await userDocSubscription?.cancel();
            userDocSubscription = null;

            if (firebaseUser == null) {
              controller.add(null);
              return;
            }

            try {
              await bindUserDoc(firebaseUser);
            } catch (error, stackTrace) {
              controller.addError(error, stackTrace);
            }
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await userDocSubscription?.cancel();
        await authSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  Future<AppUser?> signIn(
      {required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    final userDoc = _db.collection('users').doc(cred.user!.uid);
    final doc = await userDoc.get();

    if (!doc.exists) {
      await userDoc.set(_buildFallbackUserMap(cred.user!));
    }

    final freshDoc = await userDoc.get();
    if (!freshDoc.exists) return null;
    return AppUser.fromFirestore(freshDoc);
  }

  Map<String, dynamic> _buildFallbackUserMap(User firebaseUser) {
    final displayName = firebaseUser.displayName?.trim() ?? '';
    final email = firebaseUser.email?.trim() ?? '';

    return {
      'fullName': displayName.isNotEmpty ? displayName : email.split('@').first,
      'companyName': null,
      'email': email,
      'phone': firebaseUser.phoneNumber ?? '',
      'role': UserRole.customer.name,
      'clientType': ClientType.b2c.name, // Default to B2C if unknown
      'photoUrl': firebaseUser.photoURL,
      'fcmToken': null,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  Future<AppUser> register({
    required String fullName,
    String? companyName,
    required ClientType clientType,
    required String email,
    required String phone,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);

    await cred.user?.sendEmailVerification();

    final user = AppUser(
      uid: cred.user!.uid,
      fullName: fullName,
      companyName: companyName,
      clientType: clientType,
      email: email,
      phone: phone,
      role: UserRole.customer,
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(user.uid).set(user.toMap());
    await cred.user!.updateDisplayName(fullName);
    return user;
  }

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  bool isEmailVerified() {
    final user = _auth.currentUser;
    if (user == null) return false;

    return user.emailVerified;
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> updateFcmToken(String uid, String token) =>
      _db.collection('users').doc(uid).update({'fcmToken': token});

  Future<void> updateProfile(String uid,
      {String? fullName, String? companyName, String? phone, String? photoUrl}) {
    final data = <String, dynamic>{};
    if (fullName != null) data['fullName'] = fullName;
    if (companyName != null) data['companyName'] = companyName;
    if (phone != null) data['phone'] = phone;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    return _db.collection('users').doc(uid).update(data);
  }
}
