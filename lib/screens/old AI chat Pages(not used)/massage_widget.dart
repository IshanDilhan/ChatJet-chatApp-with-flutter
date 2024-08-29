// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter_markdown/flutter_markdown.dart';

// class MassageWidget extends StatelessWidget {
//   const MassageWidget({
//     super.key,
//     required this.text,
//     required this.isfromUser,
//     this.imageFile,
//   });

//   final String text;
//   final bool isfromUser;
//   final File? imageFile;

//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: isfromUser ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         constraints: const BoxConstraints(maxWidth: 520),
//         padding: const EdgeInsets.all(12),
//         margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//         decoration: BoxDecoration(
//           color: isfromUser
//               ? Theme.of(context).colorScheme.primary
//               : Theme.of(context).colorScheme.secondary,
//           borderRadius: BorderRadius.circular(18.0),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               spreadRadius: 1,
//               blurRadius: 3,
//               offset: const Offset(0, 1),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (imageFile != null)
//               Container(
//                 constraints: const BoxConstraints(
//                   maxHeight: 200,
//                   maxWidth: 300,
//                 ),
//                 child: Image.file(
//                   imageFile!,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             if (text.isNotEmpty)
//               MarkdownBody(
//                 data: text,
//                 styleSheet: MarkdownStyleSheet(
//                   p: TextStyle(
//                     color: isfromUser ? Colors.white : Colors.black,
//                     fontSize: 16,
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
