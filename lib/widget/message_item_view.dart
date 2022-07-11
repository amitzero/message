import 'package:flutter/material.dart';
import 'package:message/model/message_item.dart';

class MessageItemView extends StatelessWidget {
  const MessageItemView({
    Key? key,
    required this.message,
    required this.sender,
  }) : super(key: key);

  final MessageItem message;
  final String sender;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: message.sender == sender
          ? Alignment.centerLeft
          : Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.all(5),
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: RichText(
          textAlign: message.sender == sender ? TextAlign.end : TextAlign.start,
          text: TextSpan(
            text: message.body,
            style: Theme.of(context).textTheme.bodyText1,
            children: [
              TextSpan(
                text: '    ' +
                    DateTime.fromMillisecondsSinceEpoch(int.parse(message.time))
                        .toString()
                        .substring(8, 16),
                style: Theme.of(context).textTheme.caption,
                // style: const TextStyle(
                //   backgroundColor: Colors.grey,
                // ),
              ),
              // WidgetSpan(
              //   child: Container(
              //     alignment: Alignment.centerRight,
              //     child: Container(
              //       width: 15,
              //       height: 5,
              //       color: Colors.red,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
