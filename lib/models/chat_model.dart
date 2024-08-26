import 'package:chatapp/models/massage_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final String? chatName; // Optional for group chats
  final String? chatImageURL; // Optional for group chats
  final List<String> participants;
  final String? adminId; // Optional for group chats
  String? lastMessage;
  Timestamp? lastMessageTimestamp;
  final String chatType; // "single" or "group"
  Map<String, MessageModel>? messages; // Nested map of message IDs to messages

  ChatModel({
    required this.chatId,
    this.chatName,
    this.chatImageURL,
    required this.participants,
    this.adminId,
    this.lastMessage,
    this.lastMessageTimestamp,
    required this.chatType,
    this.messages,
  });

  // Convert a ChatModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'chatName': chatName,
      'chatImageURL': chatImageURL,
      'participants': participants,
      'adminId': adminId,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp,
      'chatType': chatType,
      'messages': messages?.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  // Create a ChatModel from a Map
  factory ChatModel.fromMap(String chatId, Map<String, dynamic> map) {
    return ChatModel(
      chatId: chatId,
      chatName: map['chatName'],
      chatImageURL: map['chatImageURL'],
      participants: List<String>.from(map['participants']),
      adminId: map['adminId'],
      lastMessage: map['lastMessage'],
      lastMessageTimestamp: map['lastMessageTimestamp'],
      chatType: map['chatType'],
      messages: (map['messages'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, MessageModel.fromMap(value))),
    );
  }
}
