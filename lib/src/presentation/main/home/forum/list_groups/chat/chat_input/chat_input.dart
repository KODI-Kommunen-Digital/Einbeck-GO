import 'package:flutter/material.dart';

class ChatInput extends StatefulWidget {
  final Function(String text) onSend;

  const ChatInput({super.key, required this.onSend});

  @override
  _ChatInputState createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _editingController = TextEditingController();

  void _onSend() {
    if (_editingController.text.isNotEmpty) {
      widget.onSend(_editingController.text);
      _editingController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0), // Move it up a bit
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(.1),
              spreadRadius: 4,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Geben Sie Ihre Nachricht ein...',
                  border: InputBorder.none,
                ),
                controller: _editingController,
                onSubmitted: (value) {
                  _onSend();
                },
              ),
            ),
            IconButton(
              icon: Icon(Icons.send,
                  color: Theme.of(context).colorScheme.primary),
              onPressed: _onSend,
            ),
          ],
        ),
      ),
    );
  }
}
