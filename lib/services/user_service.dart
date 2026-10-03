import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Salva ruolo + foto profilo Base64
  Future<void> saveUserData({
    required String uid,
    required String ruolo,
    String? imageBase64,
  }) async {
    await _db.collection('utenti').doc(uid).set({
      'ruolo': ruolo,
      'imageBase64': imageBase64,
    }, SetOptions(merge: true)); //evita di sovrascrivere altri campi
  }

  // Serve al login per capire se è studente o docente
  Future<String?> getUserRole(String uid) async {
    final doc = await _db.collection('utenti').doc(uid).get();
    if (doc.exists) {
      return doc.data()?['ruolo'];
    }
    return null;
  }

  // Recupera tutti i dati dell'utente (email, ruolo, foto)
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _db.collection('utenti').doc(uid).get();
    return doc.data();
  }
}
