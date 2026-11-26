import 'package:firebase_auth/firebase_auth.dart';

User? currentFirebaseUserOrNull() {
  try {
    return FirebaseAuth.instance.currentUser;
  } on FirebaseException catch (error) {
    if (error.code == 'no-app' || error.code == 'core/no-app') return null;
    rethrow;
  }
}
