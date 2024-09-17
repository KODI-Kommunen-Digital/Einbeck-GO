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
        orElse: () => ErrorWidget("Failed to load chat."),
      ),
    );
  }
}

class ChatLoading extends StatelessWidget {
  const ChatLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class ChatLoaded extends StatefulWidget {
  final bool isAdmin;
  final int userId;
  final ForumGroupModel group;
  final List<ChatMessageModel>? messages;

  const ChatLoaded({
    super.key,
    required this.isAdmin,
    required this.userId,
    required this.group,
    this.messages,
  });

  @override
  State<ChatLoaded> createState() => _ChatLoadedState();
}

class _ChatLoadedState extends State<ChatLoaded> {
  WebSocketChannel? channel;
  Timer? pingTimer;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  int _unreadMessageCount = 0;
  bool _showNewMessageBanner = false;
  bool isLoading = false;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _fetchMessages(isInitialLoad: true);
    _connectWebsocket(widget.group.cityId ?? 1, widget.group.id);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    channel?.sink.close();
    if (pingTimer != null) {
      pingTimer?.cancel();
    }
    if (_bannerTimer != null) {
      _bannerTimer?.cancel();
    }
    _scrollController.removeListener(_onScroll); // Remove the scroll listener
    _scrollController.dispose();
    _inputFocusNode.dispose();
    context.read<GroupDetailsCubit>().resetOffset();
    super.dispose();
  }

  void _onScroll() {
    if (_isScrolledToBottom()) {
      // Reset the unread message count when scrolled to bottom
      setState(() {
        _unreadMessageCount = 0;
      });
    }
  }

  bool _isScrolledToBottom() {
    return _scrollController.offset >=
        _scrollController.position.maxScrollExtent;
  }

  Future<void> _connectWebsocket(int? cityId, int? forumId) async {
    final wsUrl = Uri.parse('ws://test.smartregion-auf.de:4000/ws');
    channel = WebSocketChannel.connect(wsUrl);
    await channel?.ready;
    final prefs = await Preferences.openBox();
    int cityId = prefs.getKeyValue(Preferences.cityId, 0);
    channel?.sink.add(jsonEncode({
      "type": "subscribe",
      "channelId": "city_${cityId}_forum_$forumId",
    }));

    channel?.stream.listen((event) {
      final decodedEvent = jsonDecode(event);

      if (decodedEvent['type'] == "newMessage" &&
          decodedEvent['senderId'] != widget.userId) {
        _fetchMessages(isInitialLoad: false);
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
    final List<ChatMessageModel> newMessages =
        await context.read<GroupDetailsCubit>().receivePublicMessages(
              context,
              widget.group.id ?? 1,
              widget.group.cityId == 0 ? 1 : widget.group.cityId,
              isInitialLoad,
            );

    if (!isInitialLoad) {
      // Check if any of the new messages are from other users
      bool hasMessagesFromOthers =
          newMessages.any((message) => message.senderId != widget.userId);

      if (hasMessagesFromOthers && !_isScrolledToBottom()) {
        setState(() {
          _unreadMessageCount += 1;
          _showNewMessageBanner = true;
        });
        _startBannerTimer();
      } else if (_isScrolledToBottom()) {
        // Reset the banner if scrolled to bottom
        setState(() {
          _unreadMessageCount = 0;
          _showNewMessageBanner = false;
        });
      }
    }

    if (isInitialLoad) {
      _scrollToBottom();
    }
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showNewMessageBanner = false;
        });
      }
    });
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
                  if (choice ==
                      Translate.of(context).translate('leave_group')) {
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
                              Translate.of(context)
                                  .translate('member_requests'),
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
          body: SafeArea(
            child: Column(
              children: [
                if (_showNewMessageBanner)
                  GestureDetector(
                    onTap: () {
                      _scrollToUnreadMessage();
                      setState(() {
                        _showNewMessageBanner = false;
                        _unreadMessageCount = 0;
                      });
                    },
                    child: Container(
                      color: const Color(0xFFe30613),
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      width: double.infinity,
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              "${Translate.of(context).translate('new_message')} ($_unreadMessageCount)",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: ChatMessageList(
                    scrollController: _scrollController,
                    inputFocusNode: _inputFocusNode,
                  ),
                ),
                ChatInput(
                  onSend: (text) async {
                    await context.read<GroupDetailsCubit>().sendMessage(
                          context,
                          widget.group.id ?? 1,
                          text,
                        );
                    _scrollToBottom();
                  },
                  focusNode: _inputFocusNode,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scrollToUnreadMessage() {
    if (_scrollController.hasClients && _unreadMessageCount > 0) {
      final unreadMessageOffset =
          _calculateOffsetForUnreadMessage(_unreadMessageCount);
      _scrollController.animateTo(
        unreadMessageOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  double _calculateOffsetForUnreadMessage(int messageCount) {
    const double messageHeight = 70.0;
    return messageHeight * messageCount;
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 600),
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
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
