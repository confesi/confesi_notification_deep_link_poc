import 'package:dartz/dartz.dart' as s;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:notification_test/deep_links.dart';

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
  void initState() {
    link(context);
    super.initState();
  }

  void link(BuildContext context) {
    final dynamicLinkStream = DeepLink();
    dynamicLinkStream.listen((s.Either<Failure, DeepLinkRoute> link) {
      link.fold(
        (failure) {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text("Errored out link"),
            ),
          );
        },
        (route) {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text("Received dynamic link: ${route.route()} with id ${(route as PostRoute).postId}"),
            ),
          );
        },
      );
    });
  }

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
              (await DeepLink().buildLink("/post?id=55", "This is a super cool post"))
                  .fold((link) => print("Link: $link"), (failure) => print("FAILURE!!"));
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
