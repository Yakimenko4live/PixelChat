class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String encryptedContent;
  final DateTime createdAt;
  final bool isRead;
  String? decryptedContent; // сделаем не final, чтобы можно было изменять

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.encryptedContent,
    required this.createdAt,
    required this.isRead,
    this.decryptedContent,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      encryptedContent: json['encrypted_content'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'encrypted_content': encryptedContent,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }
}
