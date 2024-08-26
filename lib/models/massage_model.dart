import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String messageId; // New field for message ID
  final String senderId;
  final String? text; // Optional for text messages
  final String? mediaURL; // Optional for media messages
  final String? mediaType; // "image" or "video"
  final Timestamp timestamp;
  final String status; // "sent", "delivered", "read"
  final bool deleteForEveryone;
  final bool edited;
  final Timestamp? lastMessageTimestamp; // New field

  MessageModel({
    required this.messageId, // Initialize new field
    required this.senderId,
    this.text,
    this.mediaURL,
    this.mediaType,
    required this.timestamp,
    required this.status,
    required this.deleteForEveryone,
    required this.edited,
    this.lastMessageTimestamp, // Initialize new field
  });

  // Convert a MessageModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId, // Add new field
      'senderId': senderId,
      'text': text,
      'mediaURL': mediaURL,
      'mediaType': mediaType,
      'timestamp': timestamp,
      'status': status,
      'deleteForEveryone': deleteForEveryone,
      'edited': edited,
      'lastMessageTimestamp': lastMessageTimestamp, // Add new field
    };
  }

  // Create a MessageModel from a Map
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'], // Add new field
      senderId: map['senderId'],
      text: map['text'],
      mediaURL: map['mediaURL'],
      mediaType: map['mediaType'],
      timestamp: map['timestamp'],
      status: map['status'],
      deleteForEveryone: map['deleteForEveryone'],
      edited: map['edited'],
      lastMessageTimestamp: map['lastMessageTimestamp'], // Add new field
    );
  }
}
