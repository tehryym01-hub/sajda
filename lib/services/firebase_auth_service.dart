import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';

/// Firebase passwordless (magic link) authentication.
///
/// Flow:
///  1. [sendMagicLink] stores the pending email and calls
///     sendSignInLinkToEmail (handleCodeInApp, Android package bound).
///  2. The user taps the link in the email; the App Link opens the app and
///     MainActivity forwards it over the sajda/deeplink channel.
///  3. [tryCompleteSignIn] detects auth links, re-reads the pending email
///     and calls signInWithEmailLink — FirebaseAuth then holds a session.
///  4. The ID token is exchanged on our backend (/auth/firebase-verify)
///     which binds streak data to the verified uid/email.
class FirebaseAuthService {
  static final FirebaseAuthService instance = FirebaseAuthService._();
  FirebaseAuthService._();

  static const _kPendingEmail = 'sajda_pending_email';
  static const _kPendingName = 'sajda_pending_name';

  /// Must be a domain listed in the Firebase project's authorized domains.
  static const String _continueUrl =
      'https://sajda-b8dce.firebaseapp.com/emailSignIn';
  static const String androidPackageName = 'com.sajda.dataplus';

  bool _initialized = false;
  bool get isReady => _initialized;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _initialized = true;
  }

  FirebaseAuth get _auth => FirebaseAuth.instance;

  User? get user => _initialized ? _auth.currentUser : null;
  bool get isSignedIn => user != null;

  Future<String?> get idToken async {
    final u = user;
    if (u == null) return null;
    return u.getIdToken();
  }

  Future<String> _pendingEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPendingEmail) ?? '';
  }

  static Future<void> _savePending(String email, String? name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPendingEmail, email.trim().toLowerCase());
    if (name != null && name.trim().isNotEmpty) {
      await prefs.setString(_kPendingName, name.trim());
    }
  }

  static Future<String?> takePendingName() async {
    final prefs = await SharedPreferences.getInstance();
    final n = prefs.getString(_kPendingName);
    await prefs.remove(_kPendingName);
    return (n == null || n.isEmpty) ? null : n;
  }

  static Future<void> clearPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPendingEmail);
    await prefs.remove(_kPendingName);
  }

  /// Sends the magic link. Returns null on success or an error message.
  Future<String?> sendMagicLink(String email, {String? displayName}) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty || !trimmed.contains('@')) {
      return 'invalid_email';
    }
    try {
      await ensureInitialized();
      await _savePending(trimmed, displayName);
      await _auth.sendSignInLinkToEmail(
        email: trimmed,
        actionCodeSettings: ActionCodeSettings(
          url: _continueUrl,
          handleCodeInApp: true,
          androidPackageName: androidPackageName,
          androidInstallApp: true,
          androidMinimumVersion: '1',
        ),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      await clearPending();
      return e.code;
    } catch (_) {
      return 'network';
    }
  }

  /// True when [link] is a Firebase sign-in email link (App Link or
  /// custom-tab fallback URL).
  bool isSignInLink(String link) {
    if (_initialized) return _auth.isSignInWithEmailLink(link);
    final uri = Uri.tryParse(link.trim());
    if (uri == null || uri.scheme != 'https') return false;
    return uri.path.contains('/__/auth') ||
        uri.queryParameters.containsKey('oobCode');
  }

  /// Completes the magic-link sign-in for a captured [link].
  /// Returns null on success, or an error message.
  Future<String?> tryCompleteSignIn(String link) async {
    if (!isSignInLink(link)) return null;
    try {
      await ensureInitialized();
    } catch (_) {
      return 'firebase_init_failed';
    }
    final email = await _pendingEmail();
    if (email.isEmpty) return 'pending_email_missing';
    try {
      await _auth.signInWithEmailLink(email: email, emailLink: link.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return e.code;
    } catch (_) {
      return 'network';
    }
  }

  Future<void> signOut() async {
    if (!_initialized) return;
    await clearPending();
    await _auth.signOut();
  }
}
