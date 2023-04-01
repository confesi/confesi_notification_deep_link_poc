import 'package:dartz/dartz.dart' as s;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:notification_test/db/message_db.dart';
import 'package:notification_test/deep_links.dart';
import 'package:notification_test/in_app_messages.dart';
import 'firebase_options.dart';
import 'message.dart';
import 'notifications.dart';
import 'package:drift/drift.dart' as drift;

// Firebase requires this to be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.d
  InAppMessageService service = InAppMessageService();
  // await Hive.initFlutter();
  // await service.init();

  // service.addMessage(
  //   Message(
  //     title: message.notification!.title!,
  //     body: message.notification!.body!,
  //     dateTime: DateTime.now(),
  //   ),
  // );

  //! DRIFT DB STUFF
  final entity = MessageCompanion(
    title: drift.Value(message.notification!.title!),
    content: const drift.Value("(created from notification)"),
    date: drift.Value(DateTime.now()),
  );
  AppDb db = AppDb();
  db.insertMessage(entity).then((value) => print("Inserted: $value"));

  print("======================> Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  NotificationService notifications = NotificationService();
  await notifications.initAndroidNotifications();
  // await PathProviderPlatform.instance.setMethodCallHandler(null);
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
    final messages = await _db.getAllMessages();
    print("==================> DRIFT MESSAGES: ");
    print(messages);
  }

  void displayMessages() async {
    InAppMessageService service = InAppMessageService();
    // await Hive.initFlutter();
    await service.init();
    for (var i in service.getAllMessages()) {
      print("==========================================> ${i.title} ${i.body} ${i.dateTime}");
    }
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
            onPressed: () => displayMessages(),
            child: const Text("display db"),
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
