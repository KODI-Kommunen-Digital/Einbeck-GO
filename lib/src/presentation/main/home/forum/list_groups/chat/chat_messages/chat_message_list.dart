import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heidi/src/data/model/model_chat_message.dart';
import 'package:heidi/src/presentation/main/home/forum/list_groups/chat/cubit/chat_state.dart';
import 'chat_message_item.dart';
import '../cubit/chat_cubit.dart';

class ChatMessageList extends StatelessWidget {
  const ChatMessageList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: state.messages.length,
          itemBuilder: (context, index) {
            final ChatMessageModel message = state.messages[index];
            final bool isMe = message.senderId ==
                'current_user_id'; // Replace with actual user ID check
            return ChatMessageItem(
              message: message.text ?? '', // Use the decrypted text
              isMe: isMe,
              avatarUrl: message.avatarUrl ?? '',
              isImage: message.isImage ?? false,
              imageUrl: message.imageUrl,
            );
          },
        );
      },
    );
  }
}
