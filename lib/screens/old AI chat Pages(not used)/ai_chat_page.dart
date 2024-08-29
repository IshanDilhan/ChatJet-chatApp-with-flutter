// // ignore: file_names
// import 'dart:io';
// import 'package:chatapp/screens/AI%20chat%20Pages/massage_widget.dart';

// import 'package:flutter/material.dart';
// import 'package:google_generative_ai/google_generative_ai.dart';
// import 'package:image_cropper/image_cropper.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:logger/logger.dart';

// class AiChatPage extends StatefulWidget {
//   const AiChatPage({super.key});

//   @override
//   State<AiChatPage> createState() => _AiChatPageState();
// }

// class _AiChatPageState extends State<AiChatPage> {
//   late final GenerativeModel _model;
//   late final ChatSession _chatSession;
//   final TextEditingController _messageController = TextEditingController();
//   final FocusNode _textfieldFocus = FocusNode();
//   final ScrollController _scrollController = ScrollController();
//   bool loading = false;
//   final ImagePicker _picker = ImagePicker();
//   String? filepath;
//   XFile? pickedFile;
//   // ignore: non_constant_identifier_names
//   File? Imagetogemini;

//   @override
//   void initState() {
//     super.initState();
//     _model = GenerativeModel(
//         model: 'gemini-pro',
//         apiKey:
//             'AIzaSyBsvAHqgoryJWD_NOOnhd0AdvjXjK5YFfM'); // Replace with your API key
//     _chatSession = _model.startChat();
//   }

//   Future<void> _sendChatMessage(String message, {File? imageFile}) async {
//     setState(() {
//       loading = true;
//     });

//     try {
//       if (imageFile != null) {
//         final response = await _model.generateContent([
//           Content.text(message),
//           Content.data('image/jpeg', await imageFile.readAsBytes()),
//         ]);

//         // Handle response if needed
//         Logger().i('Response from AI: $response');
//       } else {
//         final response = await _chatSession.sendMessage(
//           Content.text(message),
//         );

//         // Handle response if needed
//         Logger().i('Response from chat session: $response');
//       }

//       setState(() {
//         loading = false;
//         _scrollDown();
//       });
//     } catch (e) {
//       _showError(e.toString());
//       Logger().e('Error sending message: $e');
//     } finally {
//       _messageController.clear();
//       setState(() {
//         loading = false;
//       });
//       _textfieldFocus.requestFocus();
//     }
//   }

//   void _scrollDown() {
//     WidgetsBinding.instance.addPostFrameCallback(
//       (_) => _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent,
//         duration: const Duration(
//           milliseconds: 750,
//         ),
//         curve: Curves.easeOutCirc,
//       ),
//     );
//   }

//   void _showError(String message) {
//     showDialog<void>(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Something went wrong'),
//           content: SingleChildScrollView(
//             child: SelectableText(message),
//           ), // SingleChildScrollView
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text('OK'),
//             ),
//           ], // AlertDialog actions
//         ); // AlertDialog
//       },
//     );
//   }

//   InputDecoration textFieldDecorations() {
//     return const InputDecoration(
//       hintText: 'Enter your message...',
//       border: OutlineInputBorder(),
//     );
//   }

//   Future<void> selectImage() async {
//     //User? user = FirebaseAuth.instance.currentUser;
//     try {
//       pickedFile = await _picker.pickImage(source: ImageSource.gallery);

//       if (pickedFile != null) {
//         Logger().i('Image selected: ${pickedFile?.path}');

//         Imagetogemini =
//             // ignore: use_build_context_synchronously
//             await cropImage(context, File(pickedFile?.path as String));
//         if (Imagetogemini != null) {
//           Logger().i("Cropped correctly: ${Imagetogemini?.path}");
//         } else {
//           Logger().i("Cropping canceled or failed.");
//         }
//       } else {
//         Logger().i('Image selection was cancelled or failed.');
//       }
//     } catch (e) {
//       Logger().e('Error selecting image: $e');
//     }
//   }

//   Future<File?> cropImage(BuildContext context, File file) async {
//     try {
//       CroppedFile? croppedFile = await ImageCropper().cropImage(
//         sourcePath: file.path,
//         compressFormat: ImageCompressFormat.jpg,
//         maxHeight: 512,
//         maxWidth: 512,
//         compressQuality: 60,
//         uiSettings: [
//           AndroidUiSettings(
//             toolbarTitle: 'Cropper',
//             toolbarColor: const Color.fromARGB(255, 158, 39, 146),
//             toolbarWidgetColor: Colors.white,
//             aspectRatioPresets: [
//               CropAspectRatioPreset.original,
//               CropAspectRatioPreset.square,
//               CropAspectRatioPresetCustom(),
//             ],
//           ),
//           IOSUiSettings(
//             title: 'Cropper',
//             aspectRatioPresets: [
//               CropAspectRatioPreset.original,
//               CropAspectRatioPreset.square,
//               CropAspectRatioPresetCustom(), // IMPORTANT: iOS supports only one custom aspect ratio in preset list
//             ],
//           ),
//           WebUiSettings(
//             context: context,
//           ),
//         ],
//       );

//       if (croppedFile != null) {
//         Logger().i('Image cropped: ${croppedFile.path}');
//         return File(croppedFile.path);
//       } else {
//         Logger().i('Image cropping was cancelled or failed.');
//         return null;
//       }
//     } catch (e) {
//       Logger().e('Error cropping image: $e');
//       return null;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('AI Chat'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Message list view
//             Expanded(
//               child: ListView.builder(
//                 controller: _scrollController,
//                 itemCount: _chatSession.history.length,
//                 itemBuilder: (context, index) {
//                   final Content content = _chatSession.history.toList()[index];
//                   final text = content.parts
//                       .whereType<TextPart>()
//                       .map<String>((e) => e.text)
//                       .join('');
//                   return MassageWidget(
//                       text: text, isfromUser: content.role == 'user');
//                 },
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(
//                 vertical: 25,
//                 horizontal: 15,
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       autofocus: true,
//                       focusNode: _textfieldFocus,
//                       decoration: textFieldDecorations(),
//                       controller: _messageController,
//                       onSubmitted: _sendChatMessage,
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.attach_file),
//                     onPressed: () {
//                       selectImage();
//                     },
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.send),
//                     onPressed: () => _sendChatMessage(_messageController.text),
//                   ),
//                 ],
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

// class CropAspectRatioPresetCustom implements CropAspectRatioPresetData {
//   @override
//   (int, int)? get data => (2, 3);

//   @override
//   String get name => '2x3 (customized)';
// }
