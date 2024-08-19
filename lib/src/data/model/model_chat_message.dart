class ChatMessageModel {
  int? id;
  int? forumId;
  int? forumMemberId;
  String? message;
  String? encryptedMessage;
  String? decryptedMessage;
  String? createdAt;
  int? forumKeyId;
  int? senderId;
  String? avatarUrl;
  bool? isImage;
  String? imageUrl;
  int? userId;
  String? username;
  String? firstname;
  String? lastname;
  String? loggedInUserProfileImage;

  ChatMessageModel({
    this.id,
    this.userId,
    this.forumId,
    this.forumMemberId,
    this.message,
    this.encryptedMessage,
    this.decryptedMessage, // Initialize text in the constructor
    this.createdAt,
    this.forumKeyId,
    this.senderId,
    this.avatarUrl,
    this.isImage,
    this.imageUrl,
    this.username,
    this.firstname,
    this.lastname,
    this.loggedInUserProfileImage,
  });

  ChatMessageModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    forumId = json['forumId'];
    forumMemberId = json['forumMemberId'];
    message = json['message'];
    encryptedMessage = json['encryptedMessage'];
    decryptedMessage = json['decryptedMessage'];
    createdAt = json['createdAt'];
    forumKeyId = json['forumKeyId'];
    senderId = json['senderId'];
    avatarUrl = json['avatarUrl'];
    isImage = json['isImage'];
    imageUrl = json['imageUrl'];
    username = json['username'];
    firstname = json['firstname'];
    lastname = json['lastname'];
    loggedInUserProfileImage = json['loggedInUserProfileImage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['forumId'] = forumId;
    data['forumMemberId'] = forumMemberId;
    data['message'] = message;
    data['encryptedMessage'] = encryptedMessage;
    data['decryptedMessage'] = decryptedMessage;
    data['createdAt'] = createdAt;
    data['forumKeyId'] = forumKeyId;
    data['senderId'] = senderId;
    data['avatarUrl'] = avatarUrl;
    data['isImage'] = isImage;
    data['imageUrl'] = imageUrl;
    data['username'] = username;
    data['firstname'] = firstname;
    data['lastname'] = lastname;
    data['loggedInUserProfileImage'] = loggedInUserProfileImage;
    return data;
  }

  // Implement the copyWith method
  ChatMessageModel copyWith({
    int? id,
    int? forumId,
    int? forumMemberId,
    String? message,
    String? encryptedMessage,
    String? decryptedMessage,
    String? createdAt,
    int? forumKeyId,
    int? senderId,
    String? avatarUrl,
    bool? isImage,
    String? imageUrl,
    int? userId,
    String? username,
    String? firstname,
    String? lastname,
    String? loggedInUserProfileImage,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      forumId: forumId ?? this.forumId,
      forumMemberId: forumMemberId ?? this.forumMemberId,
      message: message,
      encryptedMessage: encryptedMessage ?? this.encryptedMessage,
      decryptedMessage: decryptedMessage ?? this.decryptedMessage,
      createdAt: createdAt ?? this.createdAt,
      forumKeyId: forumKeyId ?? this.forumKeyId,
      senderId: senderId ?? this.senderId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isImage: isImage ?? this.isImage,
      imageUrl: imageUrl ?? this.imageUrl,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      loggedInUserProfileImage:
          loggedInUserProfileImage ?? this.loggedInUserProfileImage,
    );
  }
}
