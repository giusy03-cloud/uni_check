import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveUserRole({
    required String uid,
    required String ruolo, // "studente" o "docente"
  }) async {
    await _db.collection('utenti').doc(uid).set({
      'ruolo': ruolo,
    });
  }

  Future<String?> getUserRole(String uid) async {
    final doc = await _db.collection('utenti').doc(uid).get();
    if (doc.exists) {
      return doc['ruolo'];
    }
    return null;
  }
}
