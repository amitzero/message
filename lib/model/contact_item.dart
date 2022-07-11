
class ContactItem {
  final String name;
  final String displayName;
  final String? image;
  final String status;
  final String lastMessage;
  final bool unread;
  final String token;
  final String uid;
  final String phoneNumber;
  ContactItem({
    this.name = '',
    this.displayName = '',
    this.image,
    this.status = 'online',
    this.lastMessage = 'Hey, how\'s it going?',
    this.unread = false,
    this.token = '',
    this.uid = '',
    this.phoneNumber = '',
  });
  ContactItem.fromJson(
    Map<String, dynamic> json, {
    String? displayName,
    String? status,
    String? lastMessage,
    bool? unread,
  })  : name = json['name'] as String,
        image = (json['image'] as Map?)?['url'],
        token = json['token'] as String,
        uid = json['uid'] as String,
        phoneNumber = json['phone'] as String,
        displayName = displayName ?? json['name'] as String,
        status = status ?? 'offline',
        lastMessage = lastMessage ?? '',
        unread = unread ?? false;
}
