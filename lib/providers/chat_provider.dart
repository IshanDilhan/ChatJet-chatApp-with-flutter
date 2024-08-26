import 'package:chatapp/models/chat_model.dart';
import 'package:chatapp/models/massage_model.dart';
import 'package:chatapp/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // ignore: prefer_final_fields
  Map<String, ChatModel> _chats = {};
  // ignore: prefer_final_fields
  Map<String, UserModel> _participants = {}; // Add this field
  final Logger _logger = Logger();

  Map<String, ChatModel> get chats => _chats;
  Map<String, UserModel> get participants => _participants; // Add this getter

  User? currentuser = FirebaseAuth.instance.currentUser;

  // Fetch a single chat
  Future<void> fetchChat(String chatId) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        final chatData = chatDoc.data()!;
        _chats[chatId] = ChatModel.fromMap(chatId, chatData);
        notifyListeners();
      } else {
        Logger().i('Chat with id $chatId does not exist.');
      }
    } catch (e) {
      Logger().i('Error fetching chat: $e');
    }
  }

  // Fetch all chats for a user based on their contact IDs
  Future<List<Map<String, dynamic>>> fetchChatsWithLastMessage(
      UserModel user) async {
    try {
      if (user.contacts.isEmpty) return [];

      final List<Map<String, dynamic>> chatDetails = [];

      // Fetch chat documents where the user's contacts are participants
      final chatDocs = await Future.wait(
        user.contacts.map(
          (contactId) => _firestore
              .collection('chats')
              .where('participants', arrayContains: contactId)
              .get(),
        ),
      );

      for (var chatDocList in chatDocs) {
        for (var doc in chatDocList.docs) {
          final chatData = doc.data();
          final chatId = doc.id;

          // Extract participant IDs
          final List<String> participants =
              List<String>.from(chatData['participants']);

          // Determine the chatter ID (first participant other than the current user)
          final chatterId = participants.firstWhere(
            (participantId) => participantId != user.uid,
            orElse: () => '',
          );

          if (chatterId.isNotEmpty) {
            chatDetails.add({
              'chatId': chatId,
              'chatterName':
                  '', // Placeholder; to be fetched separately if needed
              'chatteruid': chatterId,
              'chatterImageUrl':
                  '', // Placeholder; to be fetched separately if needed
              'isOnline':
                  false, // Placeholder; to be fetched separately if needed
              'lastSeen': '', // Placeholder; to be fetched separately if needed
              'lastMessage': chatData['lastMessage'] ?? '',
              'lastMessageTimestamp':
                  chatData['lastMessageTimestamp']?.toDate() ?? DateTime.now(),
            });
          }
        }
      }

      return chatDetails;
    } catch (e) {
      _logger.e('Error fetching chats with last message: $e');
      return [];
    }
  }

  Future<Map<String, UserModel>> fetchChatters(List<String> chatterIds) async {
    try {
      final Map<String, UserModel> chatters = {};

      for (var chatterId in chatterIds) {
        final userDoc =
            await _firestore.collection('users').doc(chatterId).get();
        final chatterData = userDoc.data();

        if (chatterData != null) {
          chatters[chatterId] = UserModel.fromMap(chatterData);
        }
      }

      return chatters;
    } catch (e) {
      _logger.e('Error fetching chatters: $e');
      return {};
    }
  }

  // Add or update a chat
  Future<void> saveChat(ChatModel chat) async {
    try {
      await _firestore.collection('chats').doc(chat.chatId).set(chat.toMap());
      _chats[chat.chatId] = chat;
      notifyListeners();
    } catch (e) {
      Logger().i('Error saving chat: $e');
    }
  }

  // Add or update a message in a chat
  Future<void> addMessage(
      String chatId, MessageModel message, String senderid) async {
    try {
      final messageId =
          message.timestamp.toDate().millisecondsSinceEpoch.toString();

      _logger.i('Adding message with ID: $messageId to chat: $chatId');

      // Check if the chat document exists
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        _logger.i(
            'Chat document does not exist. Creating new chat document for ID: $chatId');

        // If the chat document does not exist, create it with initial data
        final newChat = ChatModel(
          chatId: chatId,
          participants: [senderid, currentuser!.uid],
          chatType: 'single', // or 'group' based on your logic
          lastMessage: message.text,
          lastMessageTimestamp: message.timestamp,
        );

        await _firestore.collection('chats').doc(chatId).set({
          'chatId': chatId,
          'chatType': 'single', // or 'group' based on your logic
          'lastMessage': message.text, // Initial message or empty string
          'lastMessageTimestamp': message.timestamp,
        });
        _chats[chatId] = newChat;

        _logger.i(
            'New chat document created and added to local storage for chat ID: $chatId');
      }

      // Add or update the message in the chat document
      await _firestore.collection('chats').doc(chatId).update({
        'messages.$messageId': message.toMap(),
        'lastMessage': message.text,
        'lastMessageTimestamp': message.timestamp,
        'participants': FieldValue.arrayUnion([senderid, currentuser?.uid])
      });

      _logger.i('Message updated in Firestore for chat ID: $chatId');

      if (_chats.containsKey(chatId)) {
        final chat = _chats[chatId]!;

        // Update the message map
        chat.messages ??= {};
        chat.messages![messageId] = message;

        // Update last message and timestamp
        chat.lastMessage = message.text;
        chat.lastMessageTimestamp = message.timestamp;

        _logger.i('Chat updated locally for chat ID: $chatId');

        notifyListeners();
      }
    } catch (e) {
      _logger.e('Error adding message: $e');
    }
  }

  // Delete a message
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'messages.$messageId': FieldValue.delete(),
      });

      if (_chats.containsKey(chatId)) {
        final chat = _chats[chatId]!;
        chat.messages?.remove(messageId);
        notifyListeners();
      }
    } catch (e) {
      Logger().i('Error deleting message: $e');
    }
  }
}
