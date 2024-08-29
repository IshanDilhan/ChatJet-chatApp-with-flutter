import 'dart:io';
import 'package:flutter/material.dart';

class AiChatImageProvider with ChangeNotifier {
  final List<Message> _messages = [];

  List<Message> get messages => _messages;

  void addMessage({File? imageFile, required String text}) {
    final newMessage = Message(imageFile: imageFile, text: text);
    _messages.add(newMessage);
    notifyListeners();
  }

  void clearMessage() {
    _messages.clear();
    notifyListeners();
  }
}

class Message {
  final File? imageFile;
  final String text;

  Message({this.imageFile, required this.text});
}
