import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';

class FirebaseApi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Function to initialize notifications
  Future<void> initNotifications() async {
    // Request permission from the user (will prompt user)
    await _firebaseMessaging.requestPermission();

    // Fetch the FCM token for this device
    final fcmToken = await _firebaseMessaging.getToken();

    // Print the token (normally you would send this to your server)
    Logger().i('Token: $fcmToken');
  }

  // Function to handle received messages
  void handleReceivedMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Logger().i('Received a message in the foreground: ${message.messageId}');
      // Handle the message (e.g., show a notification)
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Logger().i('Message clicked! ${message.messageId}');
      // Handle the message when the user taps on it
    });
  }

  // Function to initialize foreground and background settings
  void initBackgroundSettings() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    Logger().i("Handling a background message: ${message.messageId}");
    // Handle the background message
  }
}
