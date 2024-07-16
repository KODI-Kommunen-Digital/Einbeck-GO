class ChatMessageModel {
  int? id;
  int? forumId;
  int? forumMemberId;
  String? encryptedMessage;
  String? text; // Add this property to store the decrypted message
  String? createdAt;
  int? forumKeyId;
  String? senderId;
  String? avatarUrl;
  bool? isImage;
  String? imageUrl;
  String? username;
  String? firstname;
  String? lastname;
  String? loggedInUserProfileImage;

  ChatMessageModel({
    this.id,
    this.forumId,
    this.forumMemberId,
    this.encryptedMessage,
    this.text, // Initialize text in the constructor
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
    encryptedMessage = json['encryptedMessage'];
    text = json['text'];
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
    data['encryptedMessage'] = encryptedMessage;
    data['text'] = text;
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
}
