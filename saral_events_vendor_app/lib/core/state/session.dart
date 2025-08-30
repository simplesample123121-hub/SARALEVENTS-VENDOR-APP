import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AppSession extends ChangeNotifier {
  bool _isOnboardingComplete = false;
  bool _isAuthenticated = false;
  bool _isVendorSetupComplete = false;
  bool _isPasswordRecovery = false;

  AppSession() {
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      _isAuthenticated = event.session != null || Supabase.instance.client.auth.currentSession != null;
      if (event.event == AuthChangeEvent.passwordRecovery) {
        _isPasswordRecovery = true;
      }
      notifyListeners();
    });
  }

  bool get isOnboardingComplete => _isOnboardingComplete;
  bool get isAuthenticated => _isAuthenticated;
  bool get isVendorSetupComplete => _isVendorSetupComplete;
  bool get isPasswordRecovery => _isPasswordRecovery;
  
  // Add currentUser getter to access the authenticated user
  User? get currentUser => Supabase.instance.client.auth.currentUser;

  void completeOnboarding() {
    _isOnboardingComplete = true;
    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
      _isAuthenticated = res.session != null || Supabase.instance.client.auth.currentSession != null;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> registerWithEmail(String email, String password) async {
    try {
      final res = await Supabase.instance.client.auth.signUp(email: email, password: password);
      final hasSession = res.session != null || Supabase.instance.client.auth.currentSession != null;
      _isAuthenticated = hasSession;
      return !hasSession; // true if email confirmation likely required
    } finally {
      notifyListeners();
    }
  }

  Future<void> signInWithGoogleNative() async {
    try {
      // Use the Web client ID for serverClientId (this is what the transcript shows)
      const serverClientId = '314736791162-8pq9o3hr42ibap3oesifibeotdamgdj2.apps.googleusercontent.com';
      
      final signIn = GoogleSignIn(
        serverClientId: serverClientId,
        scopes: const [
          'email',
          'profile',
        ],
      );
      
      // Ensure clean session
      await signIn.signOut();

      final account = await signIn.signIn();
      if (account == null) {
        throw Exception('Sign-in cancelled');
      }
      
      final auth = await account.authentication;
      final idToken = auth.idToken;
      
      if (idToken == null) {
        throw Exception('No Google ID token received');
      }
      
      // Sign in to Supabase with the Google ID token
      final res = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      
      _isAuthenticated = res.session != null || Supabase.instance.client.auth.currentSession != null;
      notifyListeners();
      
    } catch (e) {
      print('Google Sign-In error: $e');
      rethrow;
    }
  }

  void completeVendorSetup() {
    _isVendorSetupComplete = true;
    notifyListeners();
  }

  void signOut() {
    Supabase.instance.client.auth.signOut();
    _isAuthenticated = false;
    _isVendorSetupComplete = false;
    _isPasswordRecovery = false;
    notifyListeners();
  }

  Future<void> updatePassword(String newPassword) async {
    await Supabase.instance.client.auth.updateUser(UserAttributes(password: newPassword));
    _isPasswordRecovery = false;
    notifyListeners();
  }

  void markPasswordRecovery() {
    _isPasswordRecovery = true;
    notifyListeners();
  }
}


