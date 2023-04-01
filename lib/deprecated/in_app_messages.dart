// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:notification_test/message.dart';

// /// You must call the `init` method to initialize Hive before using this service.
// class InAppMessageService {
//   Box<Message>? box;

//   Future<void> init() async {
//     if (!Hive.isAdapterRegistered(0)) {
//       Hive.registerAdapter(MessageAdapter());
//     }
//     await Hive.initFlutter();
//     box = await Hive.openBox<Message>('in_app_messages');
//   }

//   void addMessage(Message message) => box!.add(message);

//   Iterable<Message> getAllMessages() => box!.values;

//   void deleteMessage(DateTime dateTime) {
//     for (Message message in box!.values) {
//       if (message.dateTime == dateTime) {
//         box!.delete(message.dateTime);
//         break;
//       }
//     }
//   }

//   void deleteAll() => box!.clear();

//   void dispose() {
//     Hive.close();
//   }
// }
