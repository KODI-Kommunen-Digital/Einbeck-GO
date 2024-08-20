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

  Future<List<ChatMessageModel>> receivePublicMessages(BuildContext context,
      int forumId, int? cityId, bool isInitialLoad) async {
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

    int? lastMessageId;
    if (!isInitialLoad) {
      final currentState = state;
      if (currentState is GroupDetailsStateMessagesLoaded &&
          currentState.messages.isNotEmpty) {
        lastMessageId = currentState.messages.first.id;
      }
    }

    final response = await Api.getForumChatMessages(
      forumId: forumId,
      cityId: cityId,
      lastMessageId: isInitialLoad ? 0 : lastMessageId,
      offset: 1,
    );

    List<ChatMessageModel> newMessages = [];

    if (response.data != null) {
      newMessages = await _processMessages(response.data, forumId, userMap);

      final currentState = state;

      List<ChatMessageModel> updatedMessages = [];

      if (isInitialLoad) {
        updatedMessages = newMessages;
      } else if (currentState is GroupDetailsStateMessagesLoaded &&
          !isInitialLoad) {
        updatedMessages = List.from(newMessages)..addAll(currentState.messages);
      }

      if (currentState is GroupDetailsStateLoaded) {
        emit(GroupDetailsState.messagesLoaded(
          updatedMessages,
          currentState.arguments,
          currentState.isAdmin,
          currentState.userId,
        ));
      } else if (currentState is GroupDetailsStateMessagesLoaded) {
        emit(currentState.copyWith(messages: updatedMessages));
      } else {
        emit(GroupDetailsState.messagesLoaded(
          updatedMessages,
          arguments,
          false,
          await UserRepository.getLoggedUserId(),
        ));
      }
    }
    _currentOffset = 2;
    return newMessages;
  }

  Future<List<ChatMessageModel>> _processMessages(List<dynamic> messageData,
      int forumId, Map<int?, GroupMembersModel> userMap) async {
    List<ChatMessageModel> processedMessages = [];

    for (var data in messageData) {
      final message = ChatMessageModel.fromJson(data);
      final user = userMap[message.senderId];

      String decryptedMessage = data['message'];
      try {
        if (isPrivate) {
          decryptedMessage = await _attemptDecryption(
              data['message'], forumId, data['groupKeyVersion']);
        }
      } catch (e) {
        decryptedMessage = "Decryption failed";
        logError('Failed to decrypt message ${data['id']}', e.toString());
      }

      processedMessages.add(
        message.copyWith(
          username: user?.username ?? "Unknown",
          avatarUrl: user?.image ?? "admin/ProfilePicture.png",
          message:
              decryptedMessage.isNotEmpty ? decryptedMessage : "No message",
        ),
      );
    }

    return processedMessages;
  }

  Future<String> _attemptDecryption(
      String encryptedMessage, int forumId, int groupKeyVersion) async {
    String? groupKeyData = await KeyHelper.getForumKey(
      forumId: forumId.toString(),
      groupKeyVersion: groupKeyVersion,
    );

    if (groupKeyData == null) {
      await fetchUserGroupKeys(forumId, groupKeyVersions: [groupKeyVersion]);
      groupKeyData = await KeyHelper.getForumKey(
        forumId: forumId.toString(),
        groupKeyVersion: groupKeyVersion,
      );
    }

    if (groupKeyData != null) {
      try {
        final decrypted =
            KeyHelper.decryptMessage(encryptedMessage, groupKeyData);
        final decryptedJson = jsonDecode(decrypted);
        return decryptedJson['message'];
      } catch (e) {
        throw Exception('Decryption failed');
      }
    } else {
      await fetchUserGroupKeys(forumId);

      final latestGroupKeyVersion =
          await KeyHelper.getStoredForumKeyVersion(forumId.toString());
      if (latestGroupKeyVersion != null) {
        groupKeyData = await KeyHelper.getForumKey(
          forumId: forumId.toString(),
          groupKeyVersion: latestGroupKeyVersion,
        );

        if (groupKeyData != null) {
          try {
            final decrypted =
                KeyHelper.decryptMessage(encryptedMessage, groupKeyData);
            final decryptedJson = jsonDecode(decrypted);
            return decryptedJson['message'];
          } catch (e) {
            throw Exception('Decryption failed with latest group key');
          }
        }
      }
      throw Exception('Failed to retrieve group key');
    }
  }

  Future<void> sendMessage(
      BuildContext context, int forumId, String message) async {
    final prefs = await Preferences.openBox();
    int prefCityId = prefs.getKeyValue(Preferences.cityId, 0);

    if (isPrivate) {
      try {
        await sendPrivateMessage(context, forumId, message, prefCityId);
      } catch (e) {
        if (e.toString().contains('groupKeyVersion is not the latest')) {
          await fetchUserGroupKeys(forumId);
          await sendPrivateMessage(context, forumId, message, prefCityId);
        } else {
          logError('Failed to send private message', e.toString());
        }
      }
    } else {
      await sendPublicMessage(context, forumId, message, prefCityId);
    }
  }

  Future<void> fetchOlderMessages(BuildContext context, int forumId) async {
    final prefs = await Preferences.openBox();
    int cityId = prefs.getKeyValue(Preferences.cityId, 0);

    final currentState = state;
    if (currentState is! GroupDetailsStateMessagesLoaded) {
      return;
    }

    List<ChatMessageModel> currentMessages = currentState.messages;

    // Fetching group members to map users
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
      offset: _currentOffset,
    );

    if (response.data != null && (response.data as List).isNotEmpty) {
      final newMessages =
          await Future.wait((response.data as List).map((messageData) async {
        final message = ChatMessageModel.fromJson(messageData);
        final user = userMap[message.senderId];

        String decryptedMessage = messageData['message'];
        if (isPrivate) {
          try {
            decryptedMessage =
                await decryptPrivateMessage(messageData['message'], forumId);
          } catch (e) {
            logError('Decryption failed for message ${messageData['message']}',
                e.toString());
            return message.copyWith(message: 'Decryption failed');
          }
        }

        return message.copyWith(
          message: decryptedMessage,
          username: user?.username ?? "Unknown",
          avatarUrl: user?.image ?? "admin/ProfilePicture.png",
        );
      }));

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

  Future<void> fetchUserGroupKeys(int forumId,
      {List<int>? groupKeyVersions}) async {
    await repo.fetchUserGroupKeys(forumId, version: groupKeyVersions);
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
        SnackBar(content: Text('Failed to send message: ${response.message}')),
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

    String? latestGroupKey = await _getLatestGroupKey(forumId);

    if (latestGroupKey == null) {
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
    final groupKeyVersion =
        await KeyHelper.getStoredForumKeyVersion(forumId.toString());
    final request = jsonEncode({
      'message': encryptedMessage,
      'groupKeyVersion': groupKeyVersion,
      'messageType': 1,
    });

    final response = await Api.sendChatMessage(
        forumId: forumId, cityId: prefCityId, params: request);

    if (!response.success) {
      if (response.message.contains("groupKeyVersion is not the latest")) {
        await fetchUserGroupKeys(forumId);

        latestGroupKey = await _getLatestGroupKey(forumId);
        if (latestGroupKey != null) {
          encryptedMessage = await groupEncrypt(
              jsonEncode({
                'message': message,
                'signature': signMessage,
              }),
              latestGroupKey);
          final groupKeyVersion =
              await KeyHelper.getStoredForumKeyVersion(forumId.toString());
          final retryRequest = jsonEncode({
            'message': encryptedMessage,
            'groupKeyVersion': groupKeyVersion,
            'messageType': 1,
          });

          final retryResponse = await Api.sendChatMessage(
              forumId: forumId, cityId: prefCityId, params: retryRequest);

          if (!retryResponse.success) {
            logError('Failed to send private message on retry',
                retryResponse.message);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Failed to send message: ${retryResponse.message}')),
            );
          }
        } else {
          logError('Failed to fetch the latest group key');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to fetch the latest group key')),
          );
        }
      } else {
        logError('Failed to send private message', response.message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to send message: ${response.message}')),
        );
      }
    }
  }

  Future<String?> _getLatestGroupKey(int forumId) async {
    String? latestGroupKey;
    final storedForumKeyVersion =
        await KeyHelper.getStoredForumKeyVersion(forumId.toString());

    if (storedForumKeyVersion != null) {
      latestGroupKey = await KeyHelper.getForumKey(
        forumId: forumId.toString(),
        groupKeyVersion: storedForumKeyVersion,
      );
    }
    return latestGroupKey;
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
