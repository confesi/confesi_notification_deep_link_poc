import 'package:dartz/dartz.dart' as s;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:notification_test/deep_links.dart';

import 'firebase_options.dart';
import 'notifications.dart';

// Firebase requires this to be a top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.

  print("Handling a background message: ${message.messageId}");
}

void main() async {
  //* ADDED
  WidgetsFlutterBinding.ensureInitialized();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  NotificationService notifications = NotificationService();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // print the token for dev purposes
  notifications.token.then((token) {
    token.fold((l) => print(l), (r) => print(r));
  });

  // Subscribe to token refresh stream
  notifications.onTokenRefresh((token) {
    print('==========================================> New token: $token');
  });

  // Subscribe to message received stream
  notifications.onMessage((message) {
    print('==========================================> Message received: ${message.notification?.body}');
    navigatorKey.currentState?.pushNamed('/details');
  });

  // Subscribe to message opened app stream
  notifications.onMessageOpenedApp((message) {
    print('==========================================> Notification opened in app: ${message.notification?.body}');
    navigatorKey.currentState?.pushNamed('/details');
  });

  // notifications.onBackgroundMessage
  runApp(MyApp(navigatorKey: navigatorKey));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key, required this.navigatorKey}) : super(key: key);

  final GlobalKey<NavigatorState> navigatorKey;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      navigatorKey: navigatorKey,
      initialRoute: '/', // default route
      routes: {
        '/': (context) => const HomeScreen(),
        '/details': (context) => DataScreen(data: "DATA RECEIVED!"),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
    final dynamicLinkStream = DeepLinkStream();
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
              (await DeepLinkService().buildLink("/post?id=55", "This is a super cool post"))
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
