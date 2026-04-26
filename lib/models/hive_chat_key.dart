import 'package:hive/hive.dart';

part 'hive_chat_key.g.dart';

@HiveType(typeId: 0)
class HiveChatKey {
  @HiveField(0)
  final String chatId;

  @HiveField(1)
  final List<int> sharedSecret;

  @HiveField(2)
  final DateTime createdAt;

  HiveChatKey({
    required this.chatId,
    required this.sharedSecret,
    required this.createdAt,
  });
}
