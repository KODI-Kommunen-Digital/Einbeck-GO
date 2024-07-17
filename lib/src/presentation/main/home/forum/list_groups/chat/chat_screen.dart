// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heidi/src/data/model/model_forum_group.dart';
import 'package:heidi/src/presentation/main/home/forum/list_groups/group_details/cubit/group_details_cubit.dart';
import 'package:heidi/src/presentation/main/home/forum/list_groups/group_details/cubit/group_details_state.dart';
import 'package:heidi/src/utils/configs/routes.dart';
import 'package:heidi/src/utils/translate.dart';
import 'chat_input/chat_input.dart';
import 'chat_messages/chat_message_list.dart';
import 'cubit/chat_cubit.dart';

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

  const ChatLoaded(
      {super.key,
      required this.isAdmin,
      required this.userId,
      required this.group});

  @override
  State<ChatLoaded> createState() => _ChatLoadedState();
}

class _ChatLoadedState extends State<ChatLoaded> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  await context.read<GroupDetailsCubit>().onLoad();
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
    );
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
