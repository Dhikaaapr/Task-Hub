import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // WAJIB pakai named constructor di v7.x
  static final GoogleSignIn _googleSignIn = GoogleSignIn.standard(
    scopes: ['email'],
  );

  /// SIGN IN GOOGLE (NATIVE)
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Buka dialog akun Google
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancel login
        return null;
      }

      // Ambil token
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Buat credential Firebase
      final OAuthCredential credential =
          GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      // Login Firebase
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('❌ Google Sign In Error: $e');
      rethrow;
    }
  }

  /// LOGOUT
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// USER SAAT INI
  static User? get currentUser => _auth.currentUser;
}
