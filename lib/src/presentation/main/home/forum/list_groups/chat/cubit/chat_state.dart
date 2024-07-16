import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:heidi/src/data/model/model_chat_message.dart';

part 'chat_state.freezed.dart';

@freezed
class ChatState with _$ChatState {
  const factory ChatState({
    required List<ChatMessageModel> messages,
  }) = _ChatState;

  factory ChatState.initial() => const ChatState(messages: []);
}
