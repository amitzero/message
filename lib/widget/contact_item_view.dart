import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:message/model/contact_item.dart';
import 'package:message/ui/message_page.dart';

class ContactItemView extends StatelessWidget {
  const ContactItemView({Key? key, required this.contact}) : super(key: key);

  final ContactItem contact;

  String _badgetext(String s) {
    return s.length > 2 ? '9..' : s;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Hero(
        tag: contact.name,
        child: CircleAvatar(
          backgroundImage:
              contact.image == null ? null : NetworkImage(contact.image ?? ''),
          child: contact.image != null ? null : Text(contact.name[0]),
        ),
      ),
      title: Text(
        contact.displayName + ' (${contact.name})',
      ),
      subtitle: Text(contact.lastMessage),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Badge(
            badgeColor: Colors.blue.shade300,
            showBadge: contact.unread,
            badgeContent: SizedBox(
              width: 18,
              height: 18,
              child: Text(
                contact.image == null ? _badgetext('100') : _badgetext('10'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Text(contact.status),
        ],
      ),
      onTap: () {
        Navigator.pushNamed(
          context,
          MessagePage.routeName,
          arguments: contact,
        );
      },
    );
  }
}
