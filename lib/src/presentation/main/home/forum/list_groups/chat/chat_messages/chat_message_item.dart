import 'package:flutter/material.dart';

class ChatMessageItem extends StatelessWidget {
  final String message;
  final bool isMe;
  final String avatarUrl;
  final bool isImage;
  final String? imageUrl;

  const ChatMessageItem({
    super.key,
    required this.message,
    required this.isMe,
    required this.avatarUrl,
    this.isImage = false,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMe)
          CircleAvatar(
            backgroundImage: NetworkImage(avatarUrl),
            radius: 20,
          ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              const Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Text(
                  'Wem',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            if (isImage && imageUrl != null)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 5.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    imageUrl!,
                    width: 200,
                  ),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.symmetric(vertical: 5.0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isMe ? Colors.blue : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message,
                  style: TextStyle(color: isMe ? Colors.white : Colors.black),
                ),
              ),
            const Padding(
              padding: EdgeInsets.only(top: 4.0),
              child: Text(
                'Fri Jul 12 2024', // Static date for now, you can update it dynamically as needed
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        ),
        if (isMe) const SizedBox(width: 10),
        if (isMe)
          CircleAvatar(
            backgroundImage: NetworkImage(avatarUrl),
            radius: 20,
          ),
      ],
    );
  }
}
