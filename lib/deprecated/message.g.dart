// // GENERATED CODE - DO NOT MODIFY BY HAND

// part of 'message.dart';

// // **************************************************************************
// // TypeAdapterGenerator
// // **************************************************************************

// class MessageAdapter extends TypeAdapter<Message> {
//   @override
//   final int typeId = 0;

//   @override
//   Message read(BinaryReader reader) {
//     final numOfFields = reader.readByte();
//     final fields = <int, dynamic>{
//       for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
//     };
//     return Message(
//       dateTime: fields[0] as DateTime,
//       title: fields[1] as String,
//       body: fields[2] as String,
//     );
//   }

//   @override
//   void write(BinaryWriter writer, Message obj) {
//     writer
//       ..writeByte(3)
//       ..writeByte(0)
//       ..write(obj.dateTime)
//       ..writeByte(1)
//       ..write(obj.title)
//       ..writeByte(2)
//       ..write(obj.body);
//   }

//   @override
//   int get hashCode => typeId.hashCode;

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is MessageAdapter &&
//           runtimeType == other.runtimeType &&
//           typeId == other.typeId;
// }
