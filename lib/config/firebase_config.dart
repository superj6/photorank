/// Firebase Cloud Messaging for "your photo finished #N" pushes. Provided at
/// build time; with nothing set the app never touches Firebase.
///   --dart-define=FIREBASE_API_KEY=… --dart-define=FIREBASE_APP_ID=…
///   --dart-define=FIREBASE_SENDER_ID=… --dart-define=FIREBASE_PROJECT_ID=…
class FirebaseConfig {
  FirebaseConfig._();
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static bool get configured => apiKey.isNotEmpty && appId.isNotEmpty && senderId.isNotEmpty && projectId.isNotEmpty;
}
