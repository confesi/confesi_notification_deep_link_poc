import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId} ${message.data['path']}");
}

void main() async {
  //* ADDED
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  print(await messaging.getToken());
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("YOU CLICKED THE NOTIFICATION BUDDYHAHAHHAHAHA");
    navigatorKey.currentState?.pushNamed('/details');
  });

  messaging.onTokenRefresh.listen((String token) {
    print("TOKEN REFRESHED: $token");
  });

  messaging.subscribeToTopic("dogs");

  // await messaging.getInitialMessage().then((value) => print("GOT GOT GOT GOT GOT GOT ${value!.notification!.title}"));

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');
    navigatorKey.currentState?.pushNamed('/details');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification!.title} ${message.notification!.body}');
    }
    print("PATH ${message.data['path']}");
  });
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  //! Dynamic links
  // Check if you received the link via `getInitialLink` first
  final PendingDynamicLinkData? initialLink = await FirebaseDynamicLinks.instance.getInitialLink();

  if (initialLink != null) {
    final Uri deepLink = initialLink.link;
    // Example of using the dynamic link to push the user to a different screen
    print("DEEPLINK 1: ${deepLink.path}");
  }

  FirebaseDynamicLinks.instance.onLink.listen(
    (pendingDynamicLinkData) {
      print("DDDDDD: ${pendingDynamicLinkData.link.query}");
      // Set up the `onLink` event listener next as it may be received here
      final Uri deepLink = pendingDynamicLinkData.link;
      // Example of using the dynamic link to push the user to a different screen
      print("DEEPLINK 2: ${deepLink.path}");
    },
  );
  runApp(MyApp(settings: settings, navigatorKey: navigatorKey));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.settings, required this.navigatorKey});

  final NotificationSettings settings;
  final GlobalKey<NavigatorState> navigatorKey;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Demo',
      initialRoute: '/', // default route
      routes: {
        // '/': (context) => HomeScreen(settings: settings),
        '/details': (context) => DataScreen(data: "DATA RECEIVED!"),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(settings: settings),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.settings});

  final NotificationSettings settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('POC test #notification'),
          TextButton(
            onPressed: () async {
              var ans = await FirebaseMessaging.instance.getNotificationSettings();
              print(ans.authorizationStatus);
            },
            child: Text("tap"),
          ),
          TextButton(
            onPressed: () async {
              FirebaseDynamicLinks.instance
                  .buildShortLink(
                    DynamicLinkParameters(
                      uriPrefix: 'https://matthewtrent.page.link',
                      link: Uri.parse('https://matthewtrent.page.link/test/?data=5&path=99'),
                      socialMetaTagParameters: SocialMetaTagParameters(
                        title: "Example of a Dynamic Link",
                        imageUrl: Uri.parse("https://matthewtrent.me/assets/biz-low-res.png"),
                        description: "This link works whether the app is installed or not!",
                      ),
                      androidParameters: AndroidParameters(
                        packageName: 'com.example.notification_test',
                        minimumVersion: 1,
                      ),
                      iosParameters: IOSParameters(
                        bundleId: 'com.example.notification_test',
                        minimumVersion: '1.0.1',
                        appStoreId: '123456789',
                      ),
                    ),
                  )
                  .then((value) => print(value.shortUrl));
            },
            child: Text("set dyn link"),
          ),
        ],
      )),
    );
  }
}

class DataScreen extends StatefulWidget {
  const DataScreen({super.key, required this.data});

  final String data;

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "data: ${widget.data}",
          style: TextStyle(fontSize: 45),
        ),
      ),
    );
  }
}
