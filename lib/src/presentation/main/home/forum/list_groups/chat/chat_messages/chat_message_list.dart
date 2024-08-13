import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:heidi/src/presentation/main/home/forum/list_groups/group_details/cubit/group_details_cubit.dart';
import 'package:heidi/src/presentation/main/home/forum/list_groups/group_details/cubit/group_details_state.dart';

class ChatMessageList extends StatefulWidget {
  final ScrollController scrollController;
  final FocusNode inputFocusNode;

  const ChatMessageList({
    super.key,
    required this.scrollController,
    required this.inputFocusNode,
  });

  @override
  _ChatMessageListState createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  Future<void> _scrollListener() async {
    if (widget.scrollController.position.pixels ==
            widget.scrollController.position.maxScrollExtent &&
        !isLoading) {
      setState(() {
        isLoading = true;
      });

      await context
          .read<GroupDetailsCubit>()
          .fetchOlderMessages(context.read<GroupDetailsCubit>().forumId);

      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDate(String dateStr) {
    final dateTime = DateTime.parse(dateStr);
    return DateFormat('EEE MMM d yyyy, h:mm a', 'de').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupDetailsCubit, GroupDetailsState>(
      builder: (context, state) {
        return state.maybeWhen(
          messagesLoaded: (messages, group, isAdmin, userId) {
            return ListView.builder(
              controller: widget.scrollController,
              itemCount: messages.length + 1,
              reverse: true,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : const SizedBox.shrink();
                }
                final message = messages[index - 1];
                final isMe = message.senderId == userId;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: Row(
                    mainAxisAlignment:
                        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (!isMe)
                        CircleAvatar(
                          backgroundImage: NetworkImage(
                            message.avatarUrl ??
                                'https://smrauf1heidi.obs.eu-de.otc.t-systems.com/admin/ProfilePicture.png',
                          ),
                        ),
                      if (!isMe) const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                message.username ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 14),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? const Color(0xFFe5634d)
                                  : const Color(0xFF202123),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              message.message ?? 'No message',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                              softWrap: true,
                            ),
                          ),
                          Text(
                            formatDate(message.createdAt!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      if (isMe) const SizedBox(width: 10),
                    ],
                  ),
                );
              },
            );
          },
          orElse: () => const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
