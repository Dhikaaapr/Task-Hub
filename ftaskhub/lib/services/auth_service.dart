import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../models/task_hub_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  User? _currentUser;

  User? getCurrentUser() => _currentUser;

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled the sign-in

      // Create a User object from Google user data
      _currentUser = User(
        id: googleUser.id,  // Google Sign-In guarantees id is not null
        name: googleUser.displayName ?? 'Google User',
        email: googleUser.email,  // Google Sign-In guarantees email is not null
        avatarUrl: googleUser.photoUrl ?? '',  // photoUrl can be null
      );

      // Initialize the task hub service with the user
      TaskHubService().initialize();
      
      return _currentUser;
    } catch (error) {
      // In production, use proper logging instead of print
      // print('Error signing in with Google: $error');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  bool isSignedIn() {
    return _currentUser != null;
  }

  Future<User?> signInWithEmail(String email, String password) async {
    // In a real app, this would connect to a backend service
    // For now, we'll create a basic user object
    if (email.isNotEmpty && password.length >= 6) {
      _currentUser = User(
        id: email, // In a real app, this would be a unique ID from the backend
        name: _extractNameFromEmail(email),
        email: email,
        avatarUrl: '', // Could use gravatar or similar service
      );

      TaskHubService().initialize();
      return _currentUser;
    }
    return null;
  }

  String _extractNameFromEmail(String email) {
    // Extract name from email (before @ symbol)
    final namePart = email.split('@')[0];
    // Capitalize first letter
    if (namePart.length > 1) {
      return namePart[0].toUpperCase() + namePart.substring(1).toLowerCase();
    }
    return namePart.toUpperCase();
  }
}