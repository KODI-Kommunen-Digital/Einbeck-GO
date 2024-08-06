import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:heidi/src/presentation/main/home/forum/list_groups/group_details/cubit/group_details_cubit.dart';
import 'package:heidi/src/presentation/main/home/forum/list_groups/group_details/cubit/group_details_state.dart';

class ChatMessageList extends StatefulWidget {
  final ScrollController scrollController;

  const ChatMessageList({
    super.key,
    required this.scrollController,
  });

  @override
  _ChatMessageListState createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  bool isLoading = false;
  bool isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _scrollListener() async {
    if (widget.scrollController.position.pixels == 0 && !isLoading) {
      setState(() {
        isLoading = true;
      });

      double currentScrollPosition = widget.scrollController.position.pixels;
      double currentListHeight =
          widget.scrollController.position.maxScrollExtent;

      await context
          .read<GroupDetailsCubit>()
          .fetchOlderMessages(context.read<GroupDetailsCubit>().forumId);

      double newListHeight = widget.scrollController.position.maxScrollExtent;
      double heightDifference = newListHeight - currentListHeight;

      widget.scrollController.jumpTo(currentScrollPosition + heightDifference);

      setState(() {
        isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    if (widget.scrollController.hasClients) {
      widget.scrollController
          .jumpTo(widget.scrollController.position.maxScrollExtent);
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
            if (isInitialLoad) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (widget.scrollController.hasClients) {
                  widget.scrollController
                      .jumpTo(widget.scrollController.position.maxScrollExtent);
                }
              });
              isInitialLoad = false;
            }
            return ListView.builder(
              controller: widget.scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
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
                              maxWidth: MediaQuery.of(context).size.width * 0.5,
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

  @override
  void dispose() {
    widget.scrollController.removeListener(_scrollListener);
    super.dispose();
  }
}
