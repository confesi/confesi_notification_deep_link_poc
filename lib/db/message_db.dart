import 'dart:io';
import 'package:drift/drift.dart';
import 'package:notification_test/db/message_table.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:drift/native.dart';

part 'message_db.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(path.join(dbFolder.path, "message.sqlite"));

    return NativeDatabase(file);
  });
}

// todo: handle exceptions
@DriftDatabase(tables: [Message])
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<List<MessageData>> getAllMessages() => select(message).get();

  Future<int> deleteMessage(int id) => (delete(message)..where((t) => t.id.equals(id))).go();

  Future<int> insertMessage(MessageCompanion entity) async => into(message).insert(entity);

  Future<int> deleteAllMessages() => delete(message).go();
}
