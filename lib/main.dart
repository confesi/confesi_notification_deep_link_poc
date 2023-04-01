import 'package:alert_banner/widgets/alert.dart';
import 'package:dartz/dartz.dart' as s;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:notification_test/db/in_app_message.dart';
import 'package:notification_test/db/message_db.dart';
import 'package:notification_test/deep_links.dart';
import 'firebase_options.dart';
import 'notifications.dart';
import 'package:drift/drift.dart' as drift;

// Firebase requires this to be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("======================> BG handler called");
  InAppMessageService inAppMessageService = InAppMessageService();
  inAppMessageService.addMessage(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  NotificationService notifications = NotificationService();
  await notifications.initAndroidNotifications();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // print the token for dev purposes
  notifications.token.then((token) {
    token.fold((l) => print(l), (r) => print(r));
  });

  // Subscribe to token refresh stream
  notifications.onTokenRefresh((token) {
    print("======================> New token: $token");
  });

  // Subscribe to message received stream
  notifications.onMessage((message) {
    print("======================> Message received in app: ${message.notification?.body}");
    navigatorKey.currentState?.pushNamed('/details');
  });

  // Subscribe to message opened app stream
  notifications.onMessageOpenedApp((message) {
    print("======================> Notification clicked: ${message.notification?.body}");
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
        '/details': (context) => const DataScreen(data: "DATA RECEIVED!"),
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
  late AppDb _db;

  @override
  void initState() {
    link(context);
    _db = AppDb();
    displayAllMessagesFromDrift();
    super.initState();
  }

  void displayAllMessagesFromDrift() async {
    (await InAppMessageService().getAllMessages()).fold(
        (l) => print(l),
        (messageData) => showAlertBanner(
              context,
              () => print("TAPPPP"),
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.red,
                child: Text(
                  messageData.map((e) => e.title).toList().toString(),
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ));
    InAppMessageService().deleteAllMessages();
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
            child: const Text("tap"),
          ),
          TextButton(
            onPressed: () async {
              (await DeepLinkService().buildLink("/post?id=55", "This is a super cool post"))
                  .fold((link) => print("Link: $link"), (failure) => print("FAILURE!!"));
            },
            child: const Text("set dyn link"),
          ),
          TextButton(
            onPressed: () {
              final entity = MessageCompanion(
                title: const drift.Value("HEY TITLE"),
                content: const drift.Value("hEy BODY"),
                date: drift.Value(DateTime.now()),
              );
              _db.insertMessage(entity).then((value) => print("Inserted: $value"));
            },
            child: const Text("DRIFT DB (insert)"),
          ),
          TextButton(
            onPressed: () {
              _db.deleteMessage(1).then((value) => print("Deleted: $value"));
            },
            child: const Text("DRIFT DB (del one)"),
          ),
          TextButton(
            onPressed: () async {
              List<MessageData> values = await _db.getAllMessages();
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text("data: $values"),
                ),
              );
            },
            child: const Text("DRIFT DB (get all)"),
          ),
          TextButton(
            onPressed: () {
              _db.deleteAllMessages().then((value) => print("Deleted all: $value"));
            },
            child: const Text("DRIFT DELETE ALL)"),
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
