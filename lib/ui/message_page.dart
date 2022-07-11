import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:message/model/contact_item.dart';
import 'package:message/model/message_item.dart';
import 'package:message/utilities/app_data.dart';
import 'package:message/utilities/payload.dart';
import 'package:message/widget/message_item_view.dart';
import 'package:provider/provider.dart';

class MessagePage extends StatefulWidget {
  static const routeName = '/message';
  final ContactItem contactItem;
  const MessagePage({
    required this.contactItem,
    Key? key,
  }) : super(key: key);

  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  late ContactItem contactItem;
  List<MessageItem> messages = [];
  List<MessageItemView> get _messages {
    return messages
        .map((message) => MessageItemView(
              message: message,
              sender: contactItem.phoneNumber,
            ))
        .toList();
  }

  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _databaseRef = FirebaseDatabase.instance;
  final _user = FirebaseAuth.instance.currentUser!;
  late StreamSubscription _subscription;
  late AppData _appData;

  @override
  void initState() {
    super.initState();
    contactItem = widget.contactItem;
    _appData = context.read<AppData>();
    _appData.userNumber = contactItem.phoneNumber;
    _subscription = _databaseRef
        .ref('messages/${_user.phoneNumber!}/buffer/${contactItem.phoneNumber}')
        .onChildAdded
        .listen((event) {
      final message = MessageItem.fromJson(event.snapshot.value as Map);
      log('${event.snapshot.value}', name: 'new message');
      setState(() {
        messages.add(message);
      });
      _remove(event.snapshot.key!);
    });
  }

  void _remove(String key) async {
    await _databaseRef
        .ref('messages/${_user.phoneNumber!}/buffer/${contactItem.phoneNumber}')
        .child(key)
        .remove();
    log('child: $key removed', name: '_remove');
  }

  @override
  void dispose() {
    _subscription.cancel();
    _appData.userNumber = null;
    super.dispose();
  }

  void _sendMessage() async {
    if (_textController.text.isNotEmpty) {
      final message = MessageItem(
        sender: _user.phoneNumber!,
        body: _textController.text,
        time: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      setState(() {
        messages.add(message);
      });
      try {
        await _databaseRef
            .ref(
                'messages/${contactItem.phoneNumber}/buffer/${_user.phoneNumber!}')
            .child(message.time)
            .set(message.toJson());
      } catch (e) {
        log('Error on live database update', error: e, name: '_MessagesState');
      }
      sendPushMessage(_textController.text);
      _textController.clear();
      _focusNode.requestFocus();
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String constructFCMPayload(String body) => Payload(
        senderName: _user.displayName!,
        senderPhoneNumber: _user.phoneNumber!,
        senderId: _user.uid,
        body: body,
      ).get(contactItem.token);

  Future<void> sendPushMessage(String body) async {
    try {
      var response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization':
              'key=AAAAYwfMVW0:APA91bG3xklVuT2x9GVO0l6JqlTzwGTvy2ynw7LAt3lljnp6QQEB8cB63OP5CY0JsqV6wAy7ENcsKpvM7_O_Xq0d4KETlp2LvmgavNYFS9d0vc1BIowruBXK0hjd0EwTW3RJCr91qh1-',
        },
        body: constructFCMPayload(body),
      );
      log(
        'FCM message success: ${jsonDecode(response.body)['success']}',
        name: runtimeType.toString(),
      );
    } catch (e) {
      log(
        'error on send push notification',
        error: e,
        name: runtimeType.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            contactItem.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: 50,
            height: 50,
            child: Hero(
              tag: contactItem.name,
              child: CircleAvatar(
                // radius: 30,
                foregroundImage: contactItem.image == null
                    ? null
                    : NetworkImage(contactItem.image ?? ''),
                child: contactItem.image != null
                    ? null
                    : Text(contactItem.name[0]),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (c, i) => _messages[i],
              separatorBuilder: (c, i) => Divider(
                height: _messages[i].sender == _messages[i + 1].sender ? 0 : 5,
                color: Colors.transparent,
              ),
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                    onSubmitted: (_) {
                      if (_textController.text.isNotEmpty) {
                        _sendMessage();
                      }
                    },
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                IconButton(
                    icon: Icon(Icons.send,
                        color: _textController.text.isEmpty
                            ? Colors.grey
                            : Colors.blue),
                    onPressed:
                        _textController.text.isNotEmpty ? _sendMessage : () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
