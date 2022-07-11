
class MessageItem {
  final String sender;
  final String body;
  final String time;
  const MessageItem({this.sender = '', this.body = '', this.time = ''});
  Map<String, dynamic> toJson() => {
        'sender': sender,
        'body': body,
        'time': time,
      };

  factory MessageItem.fromJson(Map<dynamic, dynamic> json) {
    return MessageItem(
      sender: json['sender'] as String,
      body: json['body'] as String,
      time: json['time'] as String,
    );
  }
}