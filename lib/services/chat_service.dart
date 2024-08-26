import 'package:chatapp/models/massage_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatapp/models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new chat
  Future<void> createChat(ChatModel chat) async {
    await _firestore.collection('chats').doc(chat.chatId).set(chat.toMap());
  }

  // Fetch a specific chat by ID
  Future<ChatModel?> getChat(String chatId) async {
    DocumentSnapshot snapshot =
        await _firestore.collection('chats').doc(chatId).get();
    if (snapshot.exists) {
      return ChatModel.fromMap(chatId, snapshot.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Add a message to a chat
  Future<void> addMessage(String chatId, MessageModel message) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc()
        .set(message.toMap());
    // Optionally update chat metadata such as lastMessage and lastMessageTimestamp
  }

  // Fetch messages for a specific chat
  Future<List<MessageModel>> getMessages(String chatId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();
    return snapshot.docs
        .map((doc) => MessageModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }
}
