import 'dart:developer';
import 'dart:io';
import 'package:chatapp/providers/ai_chat_image_provider.dart';
import 'package:chatapp/screens/add_image_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class GeminiChatPage extends StatefulWidget {
  const GeminiChatPage({Key? key}) : super(key: key);

  @override
  State<GeminiChatPage> createState() => _GeminiChatPageState();
}

class _GeminiChatPageState extends State<GeminiChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  XFile? pickedFile;
  // ignore: non_constant_identifier_names
  File? Imagetogemini;
  bool isimagechat = false;

  void _sendQuery(String query) {
    // setState(() {
    //   _isLoading = true;
    //   _messages.add(ChatMessage(text: query, isFromUser: true));
    // });

    // Gemini.instance.text(query).then((value) {
    //   setState(() {
    //     _messages.add(
    //         ChatMessage(text: value?.output ?? 'No output', isFromUser: false));
    //     _isLoading = false;
    //   });
    //   _scrollToEnd();
    // }).catchError((e) {
    //   setState(() {
    //     _messages.add(ChatMessage(text: 'Error: $e', isFromUser: false));
    //     _isLoading = false;
    //   });
    //   log('Gemini text exception', error: e);
    //   _scrollToEnd();
    // });
    _sendQueryWithImage();
  }

  void _sendQueryWithImage() {
    final gemini = Gemini.instance;

    final messages =
        Provider.of<AiChatImageProvider>(context, listen: false).messages;

    if (messages.isNotEmpty) {
      final lastMessage = messages.last;
      final file = lastMessage.imageFile;
      final text = lastMessage.text;

      if (file != null) {
        setState(() {
          _isLoading = true;
          _messages.add(ChatMessage(text: text ?? '', isFromUser: true));
        });

        gemini.textAndImage(
          text: text ?? '',
          images: [file.readAsBytesSync()],
        ).then((value) {
          setState(() {
            _messages.add(ChatMessage(
                text: value?.content?.parts?.last.text ?? 'No output',
                isFromUser: false));
            _isLoading = false;
          });
          _scrollToEnd();
        }).catchError((e) {
          setState(() {
            _messages.add(ChatMessage(text: 'Error: $e', isFromUser: false));
            _isLoading = false;
          });
          log('Gemini textAndImage exception', error: e);
          _scrollToEnd();
        });
      } else {
        log('No image file found');
      }
    } else {
      log('No messages found');
    }
  }

  void _selectImage() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  await _getImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                  if (Imagetogemini != null) {
                    Logger().i('go1');
                    setState(() {
                      isimagechat = true;
                    });
                    Navigator.push(
                      // ignore: use_build_context_synchronously
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddTextPage(
                                imageFile: Imagetogemini,
                              )),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  await _getImage(ImageSource.camera);
                  Navigator.of(context).pop();
                  if (Imagetogemini != null) {
                    Logger().i('go2');
                    setState(() {
                      isimagechat = true;
                    });
                    Navigator.push(
                      // ignore: use_build_context_synchronously
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddTextPage(
                                imageFile: Imagetogemini,
                              )),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      Imagetogemini = null;

      if (pickedFile != null) {
        Logger().i('Image selected: ${pickedFile?.path}');

        Imagetogemini =
            // ignore: use_build_context_synchronously
            await cropImage(context, File(pickedFile?.path as String));
        if (Imagetogemini != null) {
          Logger().i("Cropped correctly: ${Imagetogemini?.path}");
        } else {
          Logger().i("Cropping canceled or failed.");
          Imagetogemini = null;
        }
      } else {
        Logger().i('Image selection was cancelled or failed.');
        Imagetogemini = null;
      }
    } catch (e) {
      Logger().e('Error selecting image: $e');
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

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                controller: _scrollController,
                children: _messages
                    .map((message) => _buildChatBubble(message))
                    .toList()
                  ..add(_isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox.shrink()),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Enter your query',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _sendQuery(value);
                        _controller.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _selectImage,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      _sendQuery(text);
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Align(
      alignment:
          message.isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: message.isFromUser ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isFromUser ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isFromUser;

  ChatMessage({
    required this.text,
    required this.isFromUser,
  });
}

class CropAspectRatioPresetCustom implements CropAspectRatioPresetData {
  @override
  (int, int)? get data => (2, 3);

  @override
  String get name => '2x3 (customized)';
}
