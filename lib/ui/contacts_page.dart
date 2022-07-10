import 'dart:developer';

import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:message/ui/message_page.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:message/ui/profile_page.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});
  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<ContactItem> users = [];
  final List<Set<String>> _contacts = [];

  List<Widget> get _contactsView {
    return users.map((contact) => ContactItemView(contact: contact)).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future _fetchContacts() async {
    if (!await FlutterContacts.requestPermission()) {
      log('Permission denied');
      return;
    }
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    for (var contact in contacts) {
      for (var phone in contact.phones) {
        if (phone.normalizedNumber.isNotEmpty) {
          _contacts.add({contact.displayName, phone.normalizedNumber});
        }
      }
    }
    _fetchUsers(_contacts);
  }

  Future<void> _fetchUsers(List<Set<String>> numbers) async {
    var ref = FirebaseFirestore.instance.collection('users');
    // for (var number in numbers) {
    //   var user = await ref.doc(number).get();
    //   log('user: ${user.data()}', name: number);
    //   if (user.exists) {
    //     setState(() {
    //       var data = user.data()!;
    //       users.add(
    //         ContactItem(
    //           name: data['name'] as String,
    //           token: data['token'] as String,
    //           uid: data['uid'] as String,
    //           phoneNumber: user.id,
    //         ),
    //       );
    //     });
    //   }
    // }
    users.clear();
    numbers.forEachCount(10, (filterList) async {
      log('filterList: $filterList', name: 'filterList');
      var usersDocs = await ref
          .where(
            'phone',
            whereIn: filterList.map((e) => e.last).toList(),
          )
          .get();
      for (var user in usersDocs.docs) {
        var data = user.data();
        log('user: ${data['name']}', name: '_fetchUsers');
        setState(() {
          users.add(
            ContactItem.fromJson(
              data,
              displayName: filterList
                  .firstWhere((element) => element.last == data['phone'])
                  .first,
            ),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          FirebaseAuth.instance.currentUser?.displayName ?? 'Contacts',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pushNamed(ProfilePage.routeName);
            },
            child: const Text('profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchUsers(_contacts),
        child: ListView(
          children: ListTile.divideTiles(
            context: context,
            tiles: _contactsView,
          ).toList(),
        ),
      ),
    );
  }
}

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

extension<E> on List<E> {
  void forEachCount(int count, Function(List<E>) f) {
    var list = List<E>.from(this);
    while (list.isNotEmpty) {
      f(list.take(count).toList());
      list = list.skip(count).toList();
    }
  }
}
