import 'dart:async'; // Import for StreamSubscription
import 'dart:io';
import 'package:chatapp/controlers/chat_controller.dart';
import 'package:chatapp/controlers/storage_controller.dart';
import 'package:chatapp/models/chat_model.dart';
import 'package:chatapp/models/massage_model.dart';
import 'package:chatapp/screens/HomePages/user_profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:chatapp/providers/chat_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Ensure this import is present

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
  User? currentUser = FirebaseAuth.instance.currentUser;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _fetchMessages();
    _startListeningToMessages();
  }

  Future<void> _fetchMessages() async {
    try {
      // Fetch chat data initially
      await _chatProvider.fetchChat(widget.chatId);
      // Update messages based on fetched chat
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

  Future<void> _startListeningToMessages() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _logger.w('No user is currently signed in.');
      return;
    }

    final chatCollection = FirebaseFirestore.instance.collection('chats');

    chatCollection.snapshots().listen((chatSnapshots) async {
      try {
        final fetchedMessages = <MessageModel>[];

        // Iterate over the chat documents
        for (var doc in chatSnapshots.docs) {
          final chatData = doc.data();
          final chatId = doc.id;
          final chatModel = ChatModel.fromMap(chatId, chatData);

          if (chatModel.participants.contains(currentUser.uid)) {
            // Get the messages map and convert it to a list of MessageModel
            if (chatModel.messages != null) {
              final messagesList = chatModel.messages!.values.toList();
              fetchedMessages.addAll(messagesList);
            }
          }
        }

        // Sort messages by timestamp
        fetchedMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        // Update the state with the fetched messages
        if (mounted) {
          setState(() {
            _messages = fetchedMessages;
          });
        }

        _logger.i('Fetched ${_messages.length} messages for chats.');
      } catch (e) {
        _logger.e('Error processing chat snapshots: $e');
      }
    }, onError: (e) {
      _logger.e('Error listening to chat updates: $e');
    });
  }

  // Delete a message

  Future<void> deleteAllChat() async {
    try {
      // Delete the chat from Firestore
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .delete();

      // Remove the chat from the provider
      // ignore: use_build_context_synchronously
      Provider.of<ChatProvider>(context, listen: false)
          .removeChat(widget.chatId);

      _logger.i('Chat deleted successfully.');

      // Clear the local messages list and update UI
      setState(() {
        _messages = [];
      });
    } catch (e) {
      _logger.e('Error deleting chat: $e');
    }
  }

  String? filepath;
  String? profileImageUrl;
  XFile? pickedFile;
  final ImagePicker _picker = ImagePicker();
  Future<String> selectImage() async {
    User? user = FirebaseAuth.instance.currentUser;
    try {
      pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        Logger().i('Image selected: ${pickedFile?.path}');

        File? croppedImg =
            await cropImage(context, File(pickedFile?.path as String));
        if (croppedImg != null) {
          Logger().i("Cropped correctly: ${croppedImg.path}");
          setState(() {
            filepath = croppedImg.path;
          });

          final storageController = StorageController();
          final downloadURL = await storageController.uploadImage(
              'Usersimages', "${user?.uid}.jpg", croppedImg);

          if (downloadURL.isNotEmpty) {
            Logger().i("Image uploaded successfully: $downloadURL");

            // Prepare message data
          } else {
            Logger().e("Failed to upload image");
          }
          return downloadURL;
        } else {
          Logger().i("Cropping canceled or failed.");
          return '';
        }
      } else {
        Logger().i('Image selection was cancelled or failed.');
        return '';
      }
    } catch (e) {
      Logger().e('Error selecting image: $e');
      return '';
    }
  }

  Future<File?> cropImage(BuildContext context, File file) async {
    try {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: file.path,
        compressFormat: ImageCompressFormat.jpg,
        maxHeight: 512,
        maxWidth: 512,
        compressQuality: 60,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: const Color.fromARGB(255, 158, 39, 146),
            toolbarWidgetColor: Colors.white,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPresetCustom(),
            ],
          ),
          IOSUiSettings(
            title: 'Cropper',
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPresetCustom(), // IMPORTANT: iOS supports only one custom aspect ratio in preset list
            ],
          ),
          WebUiSettings(
            context: context,
          ),
        ],
      );

      if (croppedFile != null) {
        Logger().i('Image cropped: ${croppedFile.path}');
        return File(croppedFile.path);
      } else {
        Logger().i('Image cropping was cancelled or failed.');
        return null;
      }
    } catch (e) {
      Logger().e('Error cropping image: $e');
      return null;
    }
  }

  Future<void> updateImageMessageFirestore(
      String chatId, String messageId, Map<String, dynamic> messageData) async {
    try {
      final chatCollection = FirebaseFirestore.instance.collection('chats');

      // Update the specific message document within the chat
      await chatCollection
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(messageData, SetOptions(merge: true));

      Logger().i('Message updated successfully in Firestore.');
    } catch (e) {
      Logger().e('Error updating message in Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ChatController chatcontroller = ChatController(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        leading: GestureDetector(
          onTap: () {
            Navigator.push(
              // ignore: use_build_context_synchronously
              context,
              MaterialPageRoute(
                  builder: (context) => UserProfilePage(
                        userId: widget.chatteruid,
                      )),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundImage: widget.chatterImageUrl.isNotEmpty
                  ? NetworkImage(widget.chatterImageUrl)
                  : const AssetImage('assets/images.png') as ImageProvider,
            ),
          ),
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              // ignore: use_build_context_synchronously
              context,
              MaterialPageRoute(
                  builder: (context) => UserProfilePage(
                        userId: widget.chatteruid,
                      )),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.chatterName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isCurrentUser = message.senderId == currentUser!.uid;

                return Align(
                  alignment: isCurrentUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: GestureDetector(
                    onLongPress: () {
                      _showMessageOptions(message.messageId, message.text!);
                    },
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
                          if (message.mediaURL != null &&
                              message.mediaURL!.isNotEmpty)
                            Image.network(
                              message.mediaURL!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            )
                          else
                            Text(
                              message.text ?? '',
                              style: const TextStyle(fontSize: 16),
                            ),
                          const SizedBox(height: 5),
                          Text(
                            DateFormat('hh:mm a')
                                .format(message.timestamp.toDate()),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
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
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: () async {
                    String? image = await selectImage();

                    if (image.isNotEmpty) {
                      final message = await chatcontroller.sendMessage(
                          widget.chatId, widget.chatteruid, image, true, image);
                      if (message != null) {
                        setState(() {
                          _messages.insert(0, message);
                        });
                        _messageController.clear();
                        // ignore: use_build_context_synchronously
                        FocusScope.of(context).unfocus(); // Close the keyboard
                      }
                    }
                  },
                ),
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
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () async {
                      final text = _messageController.text.trim();
                      if (text.isNotEmpty && currentUser != null) {
                        final message = await chatcontroller.sendMessage(
                            widget.chatId, widget.chatteruid, text, false, '');
                        if (message != null) {
                          setState(() {
                            _messages.insert(0, message);
                          });
                          _messageController.clear();
                          // ignore: use_build_context_synchronously
                          FocusScope.of(context)
                              .unfocus(); // Close the keyboard
                        }
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

  void _showMessageOptions(String messageId, String message) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('copy as text'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Text copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_page_rounded),
              title: const Text('See Contact'),
              onTap: () {
                Navigator.push(
                  // ignore: use_build_context_synchronously
                  context,
                  MaterialPageRoute(
                      builder: (context) => UserProfilePage(
                            userId: widget.chatteruid,
                          )),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text('Delete all massges in both side'),
              onTap: () {
                Navigator.pop(context);
                //_deleteMessage(messageId, true);
                deleteAllChat();
              },
            ),
          ],
        );
      },
    );
  }
}

class CropAspectRatioPresetCustom implements CropAspectRatioPresetData {
  @override
  (int, int)? get data => (2, 3);

  @override
  String get name => '2x3 (customized)';
}
