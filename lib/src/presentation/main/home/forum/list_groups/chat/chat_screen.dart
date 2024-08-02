// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heidi/src/data/model/model_chat_message.dart';
import 'package:heidi/src/data/model/model_forum_group.dart';
import 'package:heidi/src/presentation/main/home/forum/list_groups/chat/chat_messages/chat_message_list.dart';
import 'package:heidi/src/presentation/main/home/forum/list_groups/group_details/cubit/group_details_cubit.dart';
import 'package:heidi/src/presentation/main/home/forum/list_groups/group_details/cubit/group_details_state.dart';
import 'package:heidi/src/utils/configs/preferences.dart';
import 'package:heidi/src/utils/configs/routes.dart';
import 'package:heidi/src/utils/translate.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'chat_input/chat_input.dart';

class ChatScreen extends StatefulWidget {
  final bool isAdmin;

  const ChatScreen({super.key, required this.isAdmin});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupDetailsCubit, GroupDetailsState>(
        builder: (context, state) => state.maybeWhen(
            loading: () => const ChatLoading(),
            loaded: (list, group, isAdmin, userId) => ChatLoaded(
                  group: group,
                  isAdmin: isAdmin,
                  userId: userId,
                ),
            messagesLoaded: (messages, group, isAdmin, userId) => ChatLoaded(
                  group: group,
                  isAdmin: isAdmin,
                  userId: userId,
                  messages: messages,
                ),
            orElse: () => ErrorWidget("Failed to load chat.")));
  }
}

class ChatLoading extends StatelessWidget {
  const ChatLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class ChatLoaded extends StatefulWidget {
  final bool isAdmin;
  final int userId;
  final ForumGroupModel group;
  final List<ChatMessageModel>? messages;

  const ChatLoaded(
      {super.key,
      required this.isAdmin,
      required this.userId,
      required this.group,
      this.messages});

  @override
  State<ChatLoaded> createState() => _ChatLoadedState();
}

class _ChatLoadedState extends State<ChatLoaded> {
  WebSocketChannel? channel;
  Timer? pingTimer;
  String _websocketPings = "";
  final ScrollController _scrollController = ScrollController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages(isInitialLoad: true);
    _connectWebsocket(widget.group.cityId ?? 1, widget.group.id);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    channel?.sink.close();
    if (pingTimer != null) {
      pingTimer?.cancel();
    }
    super.dispose();
  }

  Future<void> _scrollListener() async {
    if (_scrollController.position.atEdge &&
        _scrollController.position.pixels == 0) {
      if (!isLoading) {
        setState(() {
          isLoading = true;
        });
        await context
            .read<GroupDetailsCubit>()
            .fetchOlderMessages(widget.group.id ?? 1);
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _connectWebsocket(int? cityId, int? forumId) async {
    final wsUrl = Uri.parse('wss://app.einbeck.de/websocket/ws');
    channel = WebSocketChannel.connect(wsUrl);
    await channel?.ready;
    final prefs = await Preferences.openBox();
    int cityId = prefs.getKeyValue(Preferences.cityId, 0);
    // Sending channel subscription message
    channel?.sink.add(jsonEncode({
      "type": "subscribe",
      "channelId": "city_${cityId}_forum_$forumId",
    }));

    channel?.stream.listen((event) {
      final decodedEvent = jsonDecode(event);
      if (decodedEvent['type'] == "newMessage") {
        _fetchMessages(isInitialLoad: false);
        final currDate = DateTime.now().toLocal().toString();
        _websocketPings = "$event\t$currDate\n$_websocketPings";
        setState(() {});
      }
    }).onDone(() {
      if (kDebugMode) {
        print("websocket closed");
      }
    });

    Timer.periodic(const Duration(seconds: 30), (timer) {
      pingTimer = timer;
      channel?.sink.add(jsonEncode({"type": "ping"}));
    });
  }

  Future<void> _fetchMessages({required bool isInitialLoad}) async {
    // Implement the logic to fetch new messages and update the UI
    context.read<GroupDetailsCubit>().receivePublicMessages(
        widget.group.id ?? 1,
        widget.group.cityId == 0 ? 1 : widget.group.cityId);
    if (isInitialLoad) {
      _scrollToBottom(); // Only scroll to bottom on initial load or on specific actions
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupDetailsCubit, GroupDetailsState>(
        builder: (context, state) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.group.forumName ?? 'Group',
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert, // Three vertical dots icon
              ),
              onSelected: (String choice) {
                if (choice == Translate.of(context).translate('leave_group')) {
                  showLeaveGroupConfirmation(context);
                } else if (choice ==
                    Translate.of(context).translate('see_member')) {
                  Navigator.pushNamed(
                    context,
                    Routes.groupMembersDetails,
                    arguments: {
                      'groupId': widget.group.id,
                      'cityId': widget.group.cityId
                    },
                  );
                } else if (choice ==
                    Translate.of(context).translate('member_requests')) {
                  Navigator.pushNamed(context, Routes.memberRequestDetails,
                      arguments: {
                        'groupId': widget.group.id,
                        'cityId': widget.group.cityId
                      });
                } else if (choice ==
                    Translate.of(context).translate('delete_group')) {
                  showDeleteGroupConfirmation(context);
                } else if (choice ==
                    Translate.of(context).translate('edit_group')) {
                  Navigator.pushNamed(context, Routes.addGroups, arguments: {
                    'isNewGroup': false,
                    'forumDetails': widget.group
                  }).then((value) async {
                    await context
                        .read<GroupDetailsCubit>()
                        .onLoad(widget.group.id);
                    setState(() {});
                  });
                }
              },
              itemBuilder: (BuildContext context) {
                return widget.isAdmin
                    ? widget.group.isPrivate == 1
                        ? {
                            Translate.of(context).translate('leave_group'),
                            Translate.of(context).translate('see_member'),
                            Translate.of(context).translate('edit_group'),
                            Translate.of(context).translate('member_requests'),
                            Translate.of(context).translate('delete_group'),
                          }.map((String choice) {
                            return PopupMenuItem<String>(
                              value: choice,
                              child: Text(choice),
                            );
                          }).toList()
                        : {
                            Translate.of(context).translate('leave_group'),
                            Translate.of(context).translate('see_member'),
                            Translate.of(context).translate('edit_group'),
                            Translate.of(context).translate('delete_group'),
                          }.map((String choice) {
                            return PopupMenuItem<String>(
                              value: choice,
                              child: Text(choice),
                            );
                          }).toList()
                    : {
                        Translate.of(context).translate('leave_group'),
                        Translate.of(context).translate('see_member'),
                      }.map((String choice) {
                        return PopupMenuItem<String>(
                          value: choice,
                          child: Text(choice),
                        );
                      }).toList();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: state.maybeWhen(
                messagesLoaded: (messages, _, __, ___) => ChatMessageList(
                  scrollController: _scrollController,
                  messages: messages,
                ),
                orElse: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
            ChatInput(
              onSend: (text) {
                context.read<GroupDetailsCubit>().sendPublicMessage(
                      context,
                      widget.group.id ?? 1,
                      text,
                    );
                _scrollToBottom();
              },
            ),
          ],
        ),
      );
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> showLeaveGroupConfirmation(BuildContext buildContext) async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              Text(Translate.of(context).translate('group_leave_confirmation')),
          content: Text(Translate.of(context)
              .translate('Are_you_sure_you_want_to_leave_this_group')),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                await buildContext
                    .read<GroupDetailsCubit>()
                    .removeGroupMember(widget.group.id, widget.group.cityId)
                    .then((isRemoved) {
                  if (isRemoved == RemoveUser.removed) {
                    if (!mounted) return;
                    Navigator.of(context).pop(true);
                  } else if (isRemoved == RemoveUser.onlyUser) {
                    if (!mounted) return;
                    Navigator.of(context).pop(false);
                    final popUpTitle =
                        Translate.of(context).translate('only_user');
                    final content =
                        Translate.of(context).translate('only_user_in_group');
                    showAdminPopup(context, popUpTitle, content);
                  } else if (isRemoved == RemoveUser.onlyAdmin) {
                    if (!mounted) return;
                    final popUpTitle =
                        Translate.of(context).translate('only_admin');
                    final content =
                        Translate.of(context).translate('add_another_admin');
                    Navigator.of(context).pop(false);
                    showAdminPopup(context, popUpTitle, content);
                  }
                });
              },
              child: Text(Translate.of(context).translate('yes')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // No
              child: Text(Translate.of(context).translate('no')),
            ),
          ],
        );
      },
    );
    if (result == true) {
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Future<void> showDeleteGroupConfirmation(BuildContext buildContext) async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              Translate.of(context).translate('group_delete_confirmation')),
          content: Text(Translate.of(context)
              .translate('are you sure you want to delete this group?')),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                await buildContext
                    .read<GroupDetailsCubit>()
                    .requestDeleteGroup(widget.group.id, widget.group.cityId);
                if (!mounted) return;
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text(Translate.of(context).translate('yes')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // No
              child: Text(Translate.of(context).translate('no')),
            ),
          ],
        );
      },
    );
    if (result == true) {}
  }

  void showAdminPopup(BuildContext context, title, content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
