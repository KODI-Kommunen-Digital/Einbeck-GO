import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_input/chat_input.dart';
import 'chat_messages/chat_message_list.dart';
import 'cubit/chat_cubit.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatCubit(),
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage('https://example.com/avatar.jpg'),
              ),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Developer', style: TextStyle(fontSize: 16)),
                  Text('3 Online',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.call), onPressed: () {}),
            IconButton(icon: const Icon(Icons.video_call), onPressed: () {}),
            IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
          ],
        ),
        body: Column(
          children: [
            const Expanded(
              child: ChatMessageList(),
            ),
            ChatInput(
              onSend: (text) {
                context.read<ChatCubit>().sendMessage(
                    text, '1'); // Replace '1' with the actual forumId
              },
            ),
          ],
        ),
      ),
    );
  }
}
