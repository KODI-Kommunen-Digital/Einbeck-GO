// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter/material.dart';
import 'package:heidi/src/data/model/model_chat_message.dart';
import 'package:heidi/src/data/model/model_forum_group.dart';
import 'package:heidi/src/data/model/model_group_members.dart';
import 'package:heidi/src/data/model/model_group_posts.dart';
import 'package:heidi/src/data/remote/api/api.dart';
import 'package:heidi/src/data/repository/forum_repository.dart';
import 'package:heidi/src/data/repository/user_repository.dart';
import 'package:heidi/src/utils/configs/key_helper.dart';
import 'package:heidi/src/utils/configs/preferences.dart';
import 'package:intl/intl.dart';
import 'package:loggy/loggy.dart';
import 'group_details_state.dart';

enum RemoveUser { error, removed, onlyAdmin, onlyUser }

class GroupDetailsCubit extends Cubit<GroupDetailsState> {
  final ForumRepository repo;
  final ForumGroupModel arguments;
  late int forumId;
  int _currentOffset = 1;
  bool isPrivate = false;

  GroupDetailsCubit(this.repo, this.arguments)
      : super(const GroupDetailsStateLoading()) {
    forumId = arguments.id ?? 1;
    isPrivate = arguments.isPrivate == 1;
    onLoad(forumId);
  }

  Future<void> onLoad(int? forumId) async {
    final groupPostsList = <GroupPostsModel>[];
    final groupMembersList = <GroupMembersModel>[];
    bool isAdmin = false;
    final requestGroupPostResponse =
        await repo.requestGroupPosts(arguments.id, arguments.cityId);
    final requestGroupDetailResponse = await repo.requestGroupDetails(
        arguments.id ?? 1, arguments.cityId ?? 1);
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

    final userMap = {
      for (var member in groupMembersList) member.userId: member
    };

    final response = await Api.getForumChatMessages(
      forumId: forumId,
      cityId: cityId,
      lastMessageId: 0,
      offset: 1,
    );

    if (response.data != null) {
      final messages =
          await Future.wait((response.data as List).map((messageData) async {
        final message = ChatMessageModel.fromJson(messageData);
        final user = userMap[message.senderId];

        String decryptedMessage = messageData['message'];
        if (isPrivate) {
          decryptedMessage =
              await decryptPrivateMessage(messageData['message'], forumId);
        }

        return message.copyWith(
          username: user?.username,
          avatarUrl: user?.image,
          message: decryptedMessage,
        );
      }));

      final sortedMessages = messages.toList();

      final currentState = state;
      if (currentState is GroupDetailsStateLoaded) {
        emit(GroupDetailsState.messagesLoaded(
          sortedMessages,
          currentState.arguments,
          currentState.isAdmin,
          currentState.userId,
        ));
      } else if (currentState is GroupDetailsStateMessagesLoaded) {
        emit(currentState.copyWith(messages: sortedMessages));
      } else {
        emit(GroupDetailsState.messagesLoaded(
          sortedMessages,
          arguments,
          false,
          await UserRepository.getLoggedUserId(),
        ));
      }
    }
    _currentOffset = 2;
  }

  Future<void> fetchOlderMessages(int forumId) async {
    final prefs = await Preferences.openBox();
    int cityId = prefs.getKeyValue(Preferences.cityId, 0);

    final currentState = state;
    if (currentState is! GroupDetailsStateMessagesLoaded) {
      return;
    }

    List<ChatMessageModel> currentMessages = currentState.messages;

    final response = await Api.getForumChatMessages(
      forumId: forumId,
      cityId: cityId,
      lastMessageId: currentMessages.isNotEmpty ? currentMessages.last.id : 0,
      offset: _currentOffset,
    );

    if (response.data != null) {
      final newMessages =
          await Future.wait((response.data as List).map((messageData) async {
        final message = ChatMessageModel.fromJson(messageData);

        String decryptedMessage = messageData['message'];
        if (isPrivate) {
          decryptedMessage =
              await decryptPrivateMessage(messageData['message'], forumId);
        }

        return message.copyWith(message: decryptedMessage);
      }));

      // Combine new messages with current messages, maintaining the correct order
      final updatedMessages = [...currentMessages, ...newMessages];

      emit(currentState.copyWith(messages: updatedMessages));
      _currentOffset++;
    }
  }

  void resetOffset() {
    _currentOffset = 1;
  }

  Future<String> decryptPrivateMessage(
      String encryptedMessage, int forumId) async {
    final storedForumKeyVersion =
        await KeyHelper.getStoredForumKeyVersion(forumId.toString());
    if (storedForumKeyVersion == null) {
      await fetchUserGroupKeys(forumId);
    }

    final updatedForumKeyVersion =
        await KeyHelper.getStoredForumKeyVersion(forumId.toString());
    if (updatedForumKeyVersion == null) {
      throw Exception('No forum key version found');
    }

    final groupKey = await KeyHelper.getForumKey(
      forumId: forumId.toString(),
      groupKeyVersion: updatedForumKeyVersion,
    );

    if (groupKey == null) {
      throw Exception('No group key found');
    }

    final decrypted = KeyHelper.decryptMessage(encryptedMessage, groupKey);
    final decryptedJson = jsonDecode(decrypted);
    return decryptedJson['message'];
  }

  Future<void> fetchUserGroupKeys(int forumId) async {
    await repo.fetchUserGroupKeys(forumId);
  }

  Future<void> sendMessage(
      BuildContext context, int forumId, String message) async {
    final prefs = await Preferences.openBox();
    int prefCityId = prefs.getKeyValue(Preferences.cityId, 0);

    if (isPrivate) {
      await sendPrivateMessage(context, forumId, message, prefCityId);
    } else {
      await sendPublicMessage(context, forumId, message, prefCityId);
    }

    await receivePublicMessages(forumId, prefCityId);
  }

  Future<void> sendPublicMessage(
      BuildContext context, int forumId, String message, int prefCityId) async {
    final request = jsonEncode({
      'message': message,
      'groupKeyVersion': 0,
      'messageType': 1,
    });

    final response = await Api.sendChatMessage(
        forumId: forumId, cityId: prefCityId, params: request);

    if (!response.success) {
      logError('Failed to send public message', response.message);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  Future<void> sendPrivateMessage(
      BuildContext context, int forumId, String message, int prefCityId) async {
    final userId = await UserRepository.getLoggedUserId();
    final privateKeyPem = await KeyHelper.getPrivateKey(userId.toString());

    List<int> messageBytes = utf8.encode(message);
    var signMessage = await RSA.signPKCS1v15(
        base64Encode(messageBytes), Hash.MD5, privateKeyPem);

    final storedForumKeyVersion =
        await KeyHelper.getStoredForumKeyVersion(forumId.toString());
    String? latestGroupKey;

    if (storedForumKeyVersion == null) {
      await fetchUserGroupKeys(forumId);
    }

    final updatedForumKeyVersion =
        await KeyHelper.getStoredForumKeyVersion(forumId.toString());
    if (updatedForumKeyVersion != null) {
      latestGroupKey = await KeyHelper.getForumKey(
        forumId: forumId.toString(),
        groupKeyVersion: updatedForumKeyVersion,
      );
    }

    if (latestGroupKey == null) {
      logError('Failed to get latest group key', 'Latest group key is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to send message: No valid group key')),
      );
      return;
    }

    String encryptedMessage = await groupEncrypt(
        jsonEncode({
          'message': message,
          'signature': signMessage,
        }),
        latestGroupKey);

    final request = jsonEncode({
      'message': encryptedMessage,
      'groupKeyVersion': int.parse(updatedForumKeyVersion!),
      'messageType': 1,
    });

    final response = await Api.sendChatMessage(
        forumId: forumId, cityId: prefCityId, params: request);

    if (!response.success) {
      logError('Failed to send private message', response.message);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  Future<String> groupEncrypt(String message, String groupKey) async {
    final iv = encrypt.IV.fromSecureRandom(16);
    final key = encrypt.Key(base64Decode(groupKey));
    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final encrypted = encrypter.encrypt(message, iv: iv);
    return "${iv.base64}:${encrypted.base64}";
  }
}
