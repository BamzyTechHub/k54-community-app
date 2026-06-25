import 'friend_model.dart';
import 'message_model.dart';

class Chat {

  final String id;
  final Friend friend;
  final List<Message> messages;


  Chat({
    required this.id,
    required this.friend,
    required this.messages,
  });

}