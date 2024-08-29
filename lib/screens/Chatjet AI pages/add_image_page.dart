import 'dart:io';
import 'package:chatapp/providers/ai_chat_image_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();
  XFile? pickedFile;
  // ignore: non_constant_identifier_names
  File? Imagetogemini;

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
    _deleteImage();
    await _getImage(ImageSource.gallery);
    setState(() {
      _imageFile = Imagetogemini;
    });
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      pickedFile = await _picker.pickImage(source: source);
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

  void _sendToChat() {
    if (_imageFile != null || _textController.text.isNotEmpty) {
      // Access the ChatProvider to send the message
      final aiChatImageProvider =
          Provider.of<AiChatImageProvider>(context, listen: false);

      // Add the message to ChatProvider
      aiChatImageProvider.addMessage(
          imageFile: _imageFile, text: _textController.text);

      Logger().i('Send data to providers');
      Navigator.pop(context, true);
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

class CropAspectRatioPresetCustom implements CropAspectRatioPresetData {
  @override
  (int, int)? get data => (2, 3);

  @override
  String get name => '2x3 (customized)';
}
