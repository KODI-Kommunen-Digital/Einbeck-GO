import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:heidi/src/data/model/model_chat_message.dart';
import 'package:heidi/src/presentation/main/home/forum/list_groups/chat/cubit/chat_state.dart';
import 'package:encrypt/encrypt.dart';
import 'package:heidi/src/utils/configs/key_helper.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

class ChatCubit extends Cubit<ChatState> {
  WebSocketChannel? channel;

  ChatCubit() : super(ChatState.initial());

  final Encrypter aesEncrypter = Encrypter(AES(Key.fromLength(32)));

  // Store keys received from the backend
  Future<void> storeKeys(
      String publicKey, String privateKey, String forumPrivateKey) async {
    await KeyHelper.storePublicKey(publicKey);
    await KeyHelper.storePrivateKey(privateKey);
    await KeyHelper.storeForumPrivateKey(forumPrivateKey);
  }

  Future<void> joinForum(String forumId) async {
    final response = await http.post(
      Uri.parse('YOUR_BACKEND_ENDPOINT/join-forum'),
      body: {'forumId': forumId},
    );
    final data = jsonDecode(response.body);

    final publicKey = data['publicKey'];
    final privateKey = data['privateKey'];
    final encryptedAesKey = data['encryptedAesKey'];
    final encryptedForumPrivateKey = data['encryptedForumPrivateKey'];

    // Decrypt AES key using user's private key
    final userPrivateKey = await KeyHelper.getPrivateKey();
    final aesKey = KeyHelper.decryptAESKey(encryptedAesKey, userPrivateKey);

    // Decrypt forum private key using AES key
    final forumPrivateKey =
        KeyHelper.decryptForumPrivateKey(encryptedForumPrivateKey, aesKey);

    // Store keys securely
    await storeKeys(publicKey, privateKey, forumPrivateKey);
  }

  // Send Message
  void sendMessage(String text, String forumId) async {
    final publicKey = await KeyHelper.getPublicKey();
    final privateKey = await KeyHelper.getPrivateKey();

    final encryptedMessage =
        Encrypter(RSA(publicKey: publicKey, privateKey: privateKey))
            .encrypt(text);

    final newMessage = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch,
      forumId: int.parse(forumId),
      forumMemberId: 1, // Replace with actual forumMemberId
      encryptedMessage: encryptedMessage.base64,
      createdAt: DateTime.now().toIso8601String(),
      forumKeyId: 1, // Replace with actual forumKeyId
      senderId: 'current_user_id',
      avatarUrl: 'https://example.com/avatar.jpg',
      isImage: false,
      imageUrl: null,
      username: 'current_user',
      firstname: 'Current',
      lastname: 'User',
      loggedInUserProfileImage: 'https://example.com/loggedinuser.jpg',
    );

    // Send the encrypted message to the backend
    await http.post(
      Uri.parse('YOUR_BACKEND_ENDPOINT/send-message'),
      body: newMessage.toJson(),
    );

    emit(state.copyWith(messages: List.from(state.messages)..add(newMessage)));
  }

  // Fetch latest messages from the server
  Future<void> fetchLatestMessages(String forumId,
      {String? lastMessageId}) async {
    final queryParameters = {
      if (lastMessageId != null) 'lastMessageId': lastMessageId,
      'limit': '50',
      'offset': '0',
    };

    final uri = Uri.https(
        'YOUR_BACKEND_ENDPOINT', '/forum/$forumId/messages', queryParameters);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> messageList = jsonDecode(response.body);
      final List<ChatMessageModel> messages = messageList
          .map((message) => ChatMessageModel.fromJson(message))
          .toList();
      emit(state.copyWith(
          messages: List.from(state.messages)..addAll(messages)));
    } else {
      throw Exception('Failed to fetch messages');
    }
  }

  // Receive Message
  void receiveMessage(ChatMessageModel message) async {
    final forumPrivateKey = await KeyHelper.getStoredForumPrivateKey();
    final decryptedMessage = Encrypter(RSA(privateKey: forumPrivateKey))
        .decrypt(Encrypted.fromBase64(message.encryptedMessage!));

    message.text =
        decryptedMessage; // Assign decrypted message text to a separate property

    emit(state.copyWith(messages: List.from(state.messages)..add(message)));
  }

  // WebSocket Connection
  void establishWebSocketConnection(String forumId) {
    channel =
        WebSocketChannel.connect(Uri.parse('wss://your-websocket-endpoint'));

    channel!.stream.listen((message) {
      // Assuming the message is a ping indicating new messages are available
      if (message == 'ping') {
        fetchLatestMessages(forumId);
      }
    });
  }

  @override
  Future<void> close() {
    channel?.sink.close();
    return super.close();
  }
}
