// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:heidi/src/data/model/model_chat_message.dart';
import 'package:heidi/src/data/model/model_forum_group.dart';
import 'package:heidi/src/data/model/model_group_members.dart';
import 'package:heidi/src/data/model/model_group_posts.dart';
import 'package:heidi/src/data/remote/api/api.dart';
import 'package:heidi/src/data/repository/forum_repository.dart';
import 'package:heidi/src/data/repository/user_repository.dart';
import 'package:heidi/src/utils/configs/preferences.dart';
import 'package:intl/intl.dart';
import 'package:loggy/loggy.dart';
import 'group_details_state.dart';

enum RemoveUser { error, removed, onlyAdmin, onlyUser }

class GroupDetailsCubit extends Cubit<GroupDetailsState> {
  final ForumRepository repo;
  final ForumGroupModel arguments;
  late int forumId;
  int offset = 1;

  GroupDetailsCubit(this.repo, this.arguments)
      : super(const GroupDetailsStateLoading()) {
    forumId = arguments.id ?? 1;
    onLoad(forumId);
  }

  Future<void> onLoad(int? forumId) async {
    final groupPostsList = <GroupPostsModel>[];
    final groupMembersList = <GroupMembersModel>[];
    bool isAdmin = false;
    final requestGroupPostResponse =
        await repo.requestGroupPosts(arguments.id, arguments.cityId);
    final requestGroupDetailResponse =
        await repo.requestGroupDetails(arguments.id, arguments.cityId);
    final response = requestGroupDetailResponse!.data;
    final group = ForumGroupModel(
      id: response['id'],
      forumName: response['forumName'],
      description: formatDescription(response['description']),
      cityId: arguments.cityId,
      image: response['image'],
      isRequested: arguments.isRequested,
      isJoined: arguments.isJoined,
      isPrivate: response['isPrivate'],
      createdAt: response['createdAt'],
    );
    if (requestGroupPostResponse?.data != null) {
      for (final post in requestGroupPostResponse!.data) {
        groupPostsList.add(GroupPostsModel(
          id: post['id'],
          forumId: post['forumId'],
          title: post['title'],
          description: post['description'],
          userId: post['userId'],
          image: post['image'],
          createdAt: DateFormat('dd.MM.yyyy').format(
            DateTime.parse(
              post['createdAt'],
            ),
          ),
          isHidden: post['isHidden'],
        ));
      }
    }

    final userId = await UserRepository.getLoggedUserId();
    final requestGroupMembersResponse =
        await repo.getGroupMembers(group.id, group.cityId);
    if (requestGroupMembersResponse?.data != null) {
      for (final member in requestGroupMembersResponse!.data) {
        groupMembersList.add(GroupMembersModel(
          userId: member['userId'],
          username: member['username'],
          memberId: member['memberId'],
          firstname: member['firstname'],
          lastname: member['lastname'],
          image: member['image'],
          isAdmin: member['isAdmin'],
          joinedAt: member['joinedAt'],
        ));
      }
      GroupMembersModel groupMember =
          groupMembersList.firstWhere((element) => element.userId == userId);
      isAdmin = groupMember.isAdmin == 1 ? true : false;
    }
    emit(GroupDetailsState.loaded(groupPostsList, group, isAdmin, userId));
  }

  Future<void> requestDeleteGroup(forumId, cityId) async {
    await repo.requestDeleteForum(forumId, cityId);
  }

  String formatDescription(String text) {
    RegExp expTags = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    String stringWithoutTags = text.replaceAll(expTags, '');

    Map<String, String> htmlEntities = {
      "&nbsp;": " ",
      "&amp;": "&",
    };

    htmlEntities.forEach((key, value) {
      stringWithoutTags = stringWithoutTags.replaceAll(key, value);
    });

    return stringWithoutTags;
  }

  Future<RemoveUser> removeGroupMember(groupId, cityId) async {
    int adminCount = 0;
    final groupMembersList = <GroupMembersModel>[];
    final requestGroupMembersResponse =
        await repo.getGroupMembers(groupId, cityId);
    if (requestGroupMembersResponse?.data != null) {
      for (final member in requestGroupMembersResponse!.data) {
        groupMembersList.add(GroupMembersModel(
          userId: member['userId'],
          username: member['username'],
          memberId: member['memberId'],
          firstname: member['firstname'],
          lastname: member['lastname'],
          image: member['image'],
          isAdmin: member['isAdmin'],
          joinedAt: member['joinedAt'],
        ));
        if (member['isAdmin'] == 1) {
          adminCount++;
        }
      }

      int userId = await UserRepository.getLoggedUserId();
      final groupMemberDetail =
          groupMembersList.firstWhere((element) => element.userId == userId);
      bool isUserAdmin = groupMemberDetail.isAdmin == 1 ? true : false;
      if (!isUserAdmin) {
        await repo.removeUserFromGroup(groupId, groupMemberDetail.memberId);
        return RemoveUser.removed;
      } else {
        if (groupMembersList.length > 1) {
          if (adminCount > 1) {
            await repo.removeUserFromGroup(groupId, groupMemberDetail.memberId);
            return RemoveUser.removed;
          } else {
            return RemoveUser.onlyAdmin;
          }
        } else {
          return RemoveUser.onlyUser;
        }
      }
    } else {
      return RemoveUser.error;
    }
  }

  Future<void> receivePublicMessages(int forumId, int? cityId) async {
    final prefs = await Preferences.openBox();
    int cityId = prefs.getKeyValue(Preferences.cityId, 0);
    final requestGroupMembersResponse =
        await repo.getGroupMembers(forumId, cityId);
    final groupMembersList = <GroupMembersModel>[];
    if (requestGroupMembersResponse?.data != null) {
      for (final member in requestGroupMembersResponse!.data) {
        groupMembersList.add(GroupMembersModel(
          userId: member['userId'],
          username: member['username'],
          memberId: member['memberId'],
          firstname: member['firstname'],
          lastname: member['lastname'],
          image: member['image'],
          isAdmin: member['isAdmin'],
          joinedAt: member['joinedAt'],
        ));
      }
    }

    // Create a map of user IDs to user details
    final userMap = {
      for (var member in groupMembersList) member.userId: member
    };

    // Fetch the messages
    final response = await Api.getForumChatMessages(
      forumId: forumId,
      cityId: cityId,
      lastMessageId: 0,
      offset: 1,
    );

    if (response.data != null) {
      final messages = (response.data as List)
          .map((messageData) {
            final message = ChatMessageModel.fromJson(messageData);
            final user = userMap[message.senderId];
            return message.copyWith(
              username: user?.username,
              avatarUrl: user?.image,
              message: messageData['message'], // Set message
            );
          })
          .toList()
          .reversed
          .toList();

      final currentState = state;
      if (currentState is GroupDetailsStateLoaded) {
        emit(GroupDetailsState.messagesLoaded(
          messages,
          currentState.arguments,
          currentState.isAdmin,
          currentState.userId,
        ));
      } else if (currentState is GroupDetailsStateMessagesLoaded) {
        emit(currentState.copyWith(messages: messages));
      } else {
        emit(GroupDetailsState.messagesLoaded(
          messages,
          arguments,
          false, // You might want to determine the correct value for isAdmin
          await UserRepository.getLoggedUserId(),
        ));
      }
    }
  }

  Future<void> fetchOlderMessages(int forumId) async {
    final prefs = await Preferences.openBox();
    int cityId = prefs.getKeyValue(Preferences.cityId, 0);

    final currentState = state;
    if (currentState is! GroupDetailsStateMessagesLoaded) {
      return;
    }

    List<ChatMessageModel> currentMessages = currentState.messages;
    int lastMessageId = 0;
    // Fetch the messages
    final response = await Api.getForumChatMessages(
      forumId: forumId,
      cityId: cityId,
      lastMessageId: lastMessageId,
      offset: ++offset,
    );

    if (response.data != null) {
      final newMessages = (response.data as List)
          .map((messageData) => ChatMessageModel.fromJson(messageData))
          .toList()
          .reversed
          .toList();

      final updatedMessages = [...newMessages, ...currentMessages];

      emit(currentState.copyWith(messages: updatedMessages));
    }
  }

  Future<void> sendPublicMessage(
      BuildContext context, int forumId, String message) async {
    final prefs = await Preferences.openBox();
    int prefCityId = prefs.getKeyValue(Preferences.cityId, 0);
    final request = jsonEncode({
      'message': message,
      'groupKeyVersion': 0,
      'messageType': 1,
    });

    final response = await Api.sendChatMessage(
        forumId: forumId, cityId: prefCityId, params: request);

    if (response.success) {
      await receivePublicMessages(forumId, prefCityId);
    } else {
      logError('Failed to send message', response.message);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }
}
