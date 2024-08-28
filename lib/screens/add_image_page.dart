import 'dart:io';
import 'package:chatapp/providers/ai_chat_image_provider.dart';
import 'package:chatapp/providers/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class AddTextPage extends StatefulWidget {
  final File? imageFile;

  const AddTextPage({required this.imageFile, super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AddTextPageState createState() => _AddTextPageState();
}

class _AddTextPageState extends State<AddTextPage> {
  final TextEditingController _textController = TextEditingController();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _imageFile = widget.imageFile;
  }

  void _deleteImage() {
    setState(() {
      _imageFile = null;
    });
  }

  Future<void> _updateImage() async {
    // Implement image update logic
  }

  void _sendToChat() {
    if (_imageFile != null || _textController.text.isNotEmpty) {
      // Access the ChatProvider to send the message
      final aiChatImageProvider =
          Provider.of<AiChatImageProvider>(context, listen: false);

      // Add the message to ChatProvider
      aiChatImageProvider.addMessage(
          imageFile: _imageFile, text: _textController.text);

      Logger().i('Send data to providers');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_imageFile != null)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.file(File(_imageFile!.path)),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _deleteImage,
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete Image'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.redAccent,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _updateImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Update Image'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: 'Add your text here',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                maxLines: 3,
                minLines: 2,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _sendToChat,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 16, 214, 119),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text('Send to Chat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
