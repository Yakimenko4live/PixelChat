import 'package:hive/hive.dart';

part 'hive_message.g.dart';

@HiveType(typeId: 1)
class HiveMessage {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String chatId;

  @HiveField(2)
  final String senderId;

  @HiveField(3)
  final String encryptedContent;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final bool isRead;

  HiveMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.encryptedContent,
    required this.createdAt,
    required this.isRead,
  });
}
