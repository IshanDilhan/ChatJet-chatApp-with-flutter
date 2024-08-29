// ignore_for_file: prefer_final_fields

import 'dart:async';

import 'package:chatapp/models/chat_model.dart';
import 'package:chatapp/models/massage_model.dart';
import 'package:chatapp/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, ChatModel> _chats = {};
  Map<String, UserModel> _participants = {};
  final Logger _logger = Logger();

  Map<String, ChatModel> get chats => _chats;
  Map<String, UserModel> get participants => _participants;
  StreamSubscription<DocumentSnapshot>? _chatSubscription;

  User? currentuser = FirebaseAuth.instance.currentUser;

  void startListeningToChat(String chatId) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _logger.w('No user is currently signed in.');
      return;
    }

    _chatSubscription
        ?.cancel(); // Cancel any existing subscription before starting a new one

    _chatSubscription =
        _firestore.collection('chats').doc(chatId).snapshots().listen(
      (chatDoc) {
        if (chatDoc.exists) {
          final chatData = chatDoc.data()!;
          _chats[chatId] = ChatModel.fromMap(chatId, chatData);
          notifyListeners();
          _logger.i('Chat with id $chatId updated in real-time.');
        } else {
          _logger.i('Chat with id $chatId does not exist.');
        }
      },
      onError: (error) {
        _logger.e('Error listening to chat updates: $error');
      },
    );
  }

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

  Future<List<Map<String, dynamic>>> fetchChatsWithLastMessage(
      UserModel user) async {
    try {
      if (user.contacts.isEmpty) return [];

      final List<Map<String, dynamic>> chatDetails = [];

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

          final List<String> participants =
              List<String>.from(chatData['participants']);

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

  Future<void> saveChat(ChatModel chat) async {
    try {
      await _firestore.collection('chats').doc(chat.chatId).set(chat.toMap());
      _chats[chat.chatId] = chat;
      notifyListeners();
    } catch (e) {
      Logger().i('Error saving chat: $e');
    }
  }

  Future<void> addMessage(
      String chatId, MessageModel message, String senderid) async {
    try {
      final messageId =
          message.timestamp.toDate().millisecondsSinceEpoch.toString();

      _logger.i('Adding message with ID: $messageId to chat: $chatId');

      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        _logger.i(
            'Chat document does not exist. Creating new chat document for ID: $chatId');

        final newChat = ChatModel(
          chatId: chatId,
          participants: [senderid, currentuser!.uid],
          chatType: 'single',
          lastMessage: message.text,
          lastMessageTimestamp: message.timestamp,
        );

        await _firestore.collection('chats').doc(chatId).set({
          'chatId': chatId,
          'chatType': 'single',
          'lastMessage': message.text,
          'lastMessageTimestamp': message.timestamp,
        });
        _chats[chatId] = newChat;

        _logger.i(
            'New chat document created and added to local storage for chat ID: $chatId');
      }

      await _firestore.collection('chats').doc(chatId).update({
        'messages.$messageId': message.toMap(),
        'lastMessage': message.text,
        'lastMessageTimestamp': message.timestamp,
        'participants': FieldValue.arrayUnion([senderid, currentuser?.uid])
      });

      _logger.i('Message updated in Firestore for chat ID: $chatId');

      if (_chats.containsKey(chatId)) {
        final chat = _chats[chatId]!;

        chat.messages ??= {};
        chat.messages![messageId] = message;

        chat.lastMessage = message.text;
        chat.lastMessageTimestamp = message.timestamp;

        _logger.i('Chat updated locally for chat ID: $chatId');

        notifyListeners();
      }
    } catch (e) {
      _logger.e('Error adding message: $e');
    }
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore.collection('chats').doc(chatId).delete();
      Logger().i('deleted from db');
      if (_chats.containsKey(chatId)) {
        final chat = _chats[chatId]!;
        chat.messages?.remove(messageId);
        notifyListeners();
      }
    } catch (e) {
      Logger().i('Error deleting message: $e');
    }
  }

  void removeChat(String chatId) {
    if (_chats.containsKey(chatId)) {
      _chats.remove(chatId);
      _logger.i('Chat with id $chatId removed from provider.');
      notifyListeners();
    } else {
      _logger.w('Attempted to remove a chat that does not exist: $chatId');
    }
  }
}
