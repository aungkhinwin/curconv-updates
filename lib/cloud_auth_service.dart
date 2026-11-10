import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'google_auth_config.dart';

class CloudAccount {
  const CloudAccount(
      {required this.uid,
      required this.email,
      required this.verified,
      required this.providers});
  final String uid;
  final String email;
  final bool verified;
  final Set<String> providers;
}

abstract class CloudAuthService {
  CloudAccount? get current;
  Stream<CloudAccount?> get changes;
  Future<void> signInEmail(String email, String password);
  Future<void> register(String email, String password);
  Future<void> signInGoogle();
  Future<void> sendReset(String email);
  Future<void> sendVerification();
  Future<void> refresh();
  Future<void> linkGoogle();
  Future<void> addPassword(String password);
  Future<void> signOut();
}

class FirebaseCloudAuth implements CloudAuthService {
  FirebaseCloudAuth({FirebaseAuth? auth, GoogleSignIn? google})
      : _auth = auth ?? FirebaseAuth.instance,
        _google = google ??
            GoogleSignIn(
              scopes: <String>['email'],
              serverClientId: _webClientId.isEmpty ? null : _webClientId,
            );

  // Web OAuth client ID (type 3), NOT an Android client ID or client secret.
  // Default is extracted from the refreshed JSON; optional build override remains.
  static const String _webClientId = String.fromEnvironment(
      'GOOGLE_WEB_CLIENT_ID',
      defaultValue: googleWebClientId);
  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  CloudAccount? _account(User? user) => user == null
      ? null
      : CloudAccount(
          uid: user.uid,
          email: user.email ?? '',
          verified: user.emailVerified,
          providers:
              user.providerData.map((UserInfo p) => p.providerId).toSet(),
        );

  @override
  CloudAccount? get current => _account(_auth.currentUser);
  @override
  Stream<CloudAccount?> get changes => _auth.userChanges().map(_account);

  @override
  Future<void> signInEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  @override
  Future<void> register(String email, String password) async {
    final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    // Account already exists if sending verification fails. UI exposes resend.
    await result.user?.sendEmailVerification();
  }

  Future<({GoogleSignInAccount account, OAuthCredential credential})?>
      _googleCredential() async {
    await _google
        .signOut(); // Offer the account picker, without revoking consent.
    final GoogleSignInAccount? account = await _google.signIn();
    if (account == null) return null; // User cancelled; not a sign-in error.
    final GoogleSignInAuthentication tokens = await account.authentication;
    if (tokens.idToken == null) {
      throw StateError(
          'Google ID token မရပါ။ SHA နဲ့ Web OAuth client configuration ကို စစ်ပါ။');
    }
    return (
      account: account,
      credential: GoogleAuthProvider.credential(
        idToken: tokens.idToken,
        accessToken: tokens.accessToken,
      )
    );
  }

  @override
  Future<void> signInGoogle() async {
    final result = await _googleCredential();
    if (result == null) return;
    // Firebase handles trusted-provider accounts. Never copy/merge another UID's data.
    await _auth.signInWithCredential(result.credential);
  }

  User _user() {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw StateError('အကောင့်မှ ထွက်သွားပါသည်။ Login ပြန်ဝင်ပါ။');
    }
    return user;
  }

  @override
  Future<void> sendReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
  @override
  Future<void> sendVerification() => _user().sendEmailVerification();
  @override
  Future<void> refresh() async {
    await _user().reload();
    await _user().getIdToken(true); // Refresh email_verified claim for Rules.
  }

  @override
  Future<void> linkGoogle() async {
    final User user = _user();
    if (!user.emailVerified) throw StateError('Email ကို အရင်အတည်ပြုပါ။');
    final result = await _googleCredential();
    if (result == null) return;
    if (result.account.email.toLowerCase() != user.email?.toLowerCase()) {
      throw StateError(
          'လက်ရှိအကောင့်နဲ့ Email တူတဲ့ Google account ကို ရွေးပါ။');
    }
    if (_auth.currentUser?.uid != user.uid) {
      throw StateError('အကောင့်ပြောင်းသွားပါသည်။');
    }
    await user.linkWithCredential(result.credential);
    await refresh();
  }

  @override
  Future<void> addPassword(String password) async {
    final User user = _user();
    if (!user.emailVerified || user.email == null) {
      throw StateError('Email ကို အရင်အတည်ပြုပါ။');
    }
    await user.linkWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password));
    await refresh();
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _google.signOut();
    } on PlatformException {/* Firebase is already signed out. */}
  }
}

String cloudAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'Email ပုံစံ မမှန်ပါ။';
      case 'weak-password':
        return 'Password အားနည်းပါသည်။ အနည်းဆုံး ၆ လုံးနှင့် project password စည်းမျဉ်းကို လိုက်နာပါ။';
      case 'email-already-in-use':
        return 'ဒီ Email မှာ အကောင့်ရှိပြီးသားပါ။ Login သို့မဟုတ် Password reset ကို သုံးပါ။';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email သို့မဟုတ် Password မမှန်ပါ။';
      case 'user-disabled':
        return 'ဒီအကောင့်ကို ပိတ်ထားပါသည်။';
      case 'operation-not-allowed':
        return 'Firebase Authentication မှာ ဒီ Login provider ကို ဖွင့်ရန်လိုပါသည်။';
      case 'account-exists-with-different-credential':
        return 'ဒီ Email ကို အခြား Login နည်းနဲ့ ဖွင့်ထားပြီးသားပါ။ အရင်နည်းနဲ့ Login ဝင်ပြီး Google ကို ချိတ်ပါ။';
      case 'credential-already-in-use':
        return 'ဒီ Login က အခြားအကောင့်တစ်ခုနဲ့ ချိတ်ထားပြီးသားပါ။ အကောင့်ဒေတာတွေ အလိုအလျောက် မပေါင်းပါ။';
      case 'provider-already-linked':
        return 'ဒီ Login နည်းကို ချိတ်ထားပြီးသားပါ။';
      case 'requires-recent-login':
        return 'လုံခြုံရေးအတွက် Logout လုပ်ပြီး Login ပြန်ဝင်ကာ ထပ်လုပ်ပါ။';
      case 'too-many-requests':
        return 'အကြိမ်များလွန်းပါသည်။ ခဏစောင့်ပြီး ပြန်လုပ်ပါ။';
      case 'network-request-failed':
        return 'အင်တာနက် ချိတ်ဆက်မှုကို စစ်ပါ။';
      default:
        return 'Login error (${error.code}): ${error.message ?? ''}';
    }
  }
  if (error is PlatformException) {
    return 'Google Login error (${error.code})။ SHA-1၊ package name၊ Google provider နဲ့ OAuth config ကို စစ်ပါ။';
  }
  return error.toString();
}
