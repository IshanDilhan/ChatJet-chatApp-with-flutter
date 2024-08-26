import 'package:chatapp/controlers/chat_controller.dart';
import 'package:chatapp/models/massage_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:chatapp/providers/chat_provider.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String chatterName;
  final String chatteruid;
  final String chatterImageUrl;
  final bool isOnline;
  final String lastSeen;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.chatterName,
    required this.chatterImageUrl,
    required this.chatteruid,
    required this.isOnline,
    required this.lastSeen,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  late ChatProvider _chatProvider;
  List<MessageModel> _messages = [];
  User? currectuser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    try {
      await _chatProvider.fetchChat(widget.chatId);
      setState(() {
        _messages =
            _chatProvider.chats[widget.chatId]?.messages?.values.toList() ?? [];
        _messages.sort((a, b) =>
            b.timestamp.compareTo(a.timestamp)); // Sort messages by timestamp
      });
    } catch (e) {
      Logger().i('Error fetching messages: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ChatController chatController = ChatController(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: widget.chatterImageUrl.isNotEmpty
                ? NetworkImage(widget.chatterImageUrl) // Load profile picture
                : const AssetImage('assets/images.png') as ImageProvider,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatterName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              widget.isOnline
                  ? 'Online'
                  : DateFormat('dd MMM yyyy, hh:mm a')
                      .format(DateTime.parse(widget.lastSeen)),
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isCurrentUser = message.senderId == currectuser!.uid;

                return Align(
                  alignment: isCurrentUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Dismissible(
                    key: UniqueKey(),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      if (isCurrentUser) {
                        _chatProvider.deleteMessage(
                            widget.chatId, message.messageId);
                        setState(() {
                          _messages.removeAt(index);
                        });
                      }
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 10),
                      decoration: BoxDecoration(
                        color:
                            isCurrentUser ? Colors.blue[200] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: isCurrentUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.text ?? '',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            DateFormat('hh:mm a')
                                .format(message.timestamp.toDate()),
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 20.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 5,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () async {
                      final text = _messageController.text.trim();
                      if (text.isNotEmpty && currectuser != null) {
                        final message = await chatController.sendMessage(
                          widget.chatId,
                          widget
                              .chatteruid, // Replace with the actual current user ID
                          text,
                        );
                        setState(() {
                          _messages.insert(0,
                              message!); // Add the new message to the top of the list
                        });
                        _messageController.clear();
                        // ignore: use_build_context_synchronously
                        FocusScope.of(context).unfocus(); // Close the keyboard
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
