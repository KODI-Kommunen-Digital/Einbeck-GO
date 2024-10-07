import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heidi/src/utils/configs/application.dart';
import 'package:intl/intl.dart';
import 'package:heidi/src/presentation/main/home/forum/list_groups/group_details/cubit/group_details_cubit.dart';
import 'package:heidi/src/presentation/main/home/forum/list_groups/group_details/cubit/group_details_state.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Widget _buildMessageContent(String messageText) {
    final urlPattern = RegExp(r'((https?:\/\/)?(www\.)[^\s]+)');
    final List<InlineSpan> textSpans = [];

    int lastIndex = 0;
    final matches = urlPattern.allMatches(messageText);

    for (final match in matches) {
      if (match.start > lastIndex) {
        textSpans.add(
          TextSpan(
            text: messageText.substring(lastIndex, match.start),
            style: const TextStyle(color: Colors.white),
          ),
        );
      }

      final url = match.group(0);
      textSpans.add(
        TextSpan(
          text: url,
          style: const TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              _launchURL(url!);
            },
        ),
      );

      lastIndex = match.end;
    }

    if (lastIndex < messageText.length) {
      textSpans.add(
        TextSpan(
          text: messageText.substring(lastIndex),
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    return RichText(
      text: TextSpan(
        children: textSpans,
      ),
      softWrap: true,
    );
  }

  void _launchURL(String url) async {
    final validUrl = url.startsWith('http') ? url : 'https://$url';
    if (await canLaunch(validUrl)) {
      await launch(validUrl);
    } else {
      throw 'Could not launch $validUrl';
    }
  }

  Future<void> _scrollListener() async {
    if (widget.scrollController.position.pixels ==
            widget.scrollController.position.maxScrollExtent &&
        !isLoading) {
      setState(() {
        isLoading = true;
      });

      await context.read<GroupDetailsCubit>().fetchOlderMessages(
          context, context.read<GroupDetailsCubit>().forumId);

      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDate(String dateStr) {
    final dateTime = DateTime.parse(dateStr).add(const Duration(hours: 2));
    return DateFormat('EEE, d. MMM yyyy, HH:mm \'Uhr\'', 'de_DE')
        .format(dateTime);
  }

  void _copyToClipboard(BuildContext context, String message) {
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nachricht in die Zwischenablage kopiert')),
    );
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
                            message.avatarUrl == "Keine Angabe"
                                ? '${Application.picturesURL}admin/ProfilePicture.png'
                                : '${Application.picturesURL}${message.avatarUrl}',
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
                                ),
                              ),
                            ),
                          GestureDetector(
                            onLongPress: () => _copyToClipboard(
                                context, message.message ?? 'No message'),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 14),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? const Color(0xFFe5634d)
                                    : const Color(0xFF202123),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: _buildMessageContent(
                                  message.message ?? 'No message'),
                            ),
                          ),
                          Text(
                            formatDate(message.createdAt!),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).shadowColor,
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
