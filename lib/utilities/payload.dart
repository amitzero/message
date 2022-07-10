import 'dart:convert';

class Payload {
  String senderName;
  String senderPhoneNumber;
  String senderId;
  String body;
  String type;
  String time;

  Payload({
    this.senderName = '',
    this.senderPhoneNumber = '',
    this.senderId = '',
    this.body = '',
    this.type = '',
    String? time = '',
  }) : time = time ?? DateTime.now().millisecondsSinceEpoch.toString();

  factory Payload.fromJson(Map<String, dynamic> json) => Payload(
        senderName: json['senderName'] as String,
        senderPhoneNumber: json['senderPhoneNumber'] as String,
        body: json['body'] as String,
        time: json['time'] as String,
        type: json['type'] as String,
        senderId: json['senderId'] as String,
      );

  String get(String to) {
    return jsonEncode(
      {
        'to': to,
        'data': {
          'senderName': senderName,
          'senderPhoneNumber': senderPhoneNumber,
          'body': body,
          'time': time,
          'type': type,
          'senderId': senderId,
        },
      },
    );
  }
}