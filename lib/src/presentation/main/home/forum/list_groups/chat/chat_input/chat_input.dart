import 'package:flutter/material.dart';
import 'package:heidi/src/utils/translate.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSend;
  final FocusNode focusNode;

  const ChatInput({super.key, required this.onSend, required this.focusNode});

  @override
  _ChatInputState createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: widget.focusNode,
              textInputAction: TextInputAction.newline,
              onSubmitted: (value) {
                if (_controller.text.isNotEmpty) {
                  widget.onSend(_controller.text);
                  _controller.clear();
                  widget.focusNode.requestFocus();
                }
              },
              decoration: InputDecoration(
                hintText: Translate.of(context).translate(
                  'type_message',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: const Color(0xFFe5634d),
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                widget.onSend(_controller.text);
                _controller.clear();
                widget.focusNode.requestFocus();
              }
            },
          ),
        ],
      ),
    );
  }
}
