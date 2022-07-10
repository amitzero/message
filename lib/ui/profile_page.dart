import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:message/ui/signup_page.dart';
import 'package:page_transition/page_transition.dart';

class ProfilePage extends StatefulWidget {
  static const routeName = '/profile';
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late DocumentReference<Map<String, dynamic>> _userRef;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.phoneNumber);
    _userRef.get().then((value) {
      setState(() {
        _user = value.data();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              actions: [
                TextButton(
                  child: const Text('Sign out'),
                  onPressed: () async {
                    log('logout', name: runtimeType.toString());
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushReplacementNamed('/');
                    // Navigator.of(context).popUntil(ModalRoute.withName('/login'));
                    // Navigator.pushReplacement(
                    //   context,
                    //   PageTransition(
                    //     type: PageTransitionType.fade,
                    //     child: const SignUpPage(),
                    //   ),
                    // );
                  },
                ),
              ],
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                expandedTitleScale: 3.75,
                titlePadding: const EdgeInsets.only(left: 50, bottom: 5),
                title: SizedBox(
                  height: 50,
                  width: 50,
                  child: CircleAvatar(
                    backgroundImage:
                        _user == null || _user!['image']?['url'] == null
                            ? const AssetImage('assets/images/profile.png')
                            : NetworkImage(_user!['image']?['url'])
                                as ImageProvider,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Name: ${_user?['name']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Email:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Phone: ${_user?['phone']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Address:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Birthday:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'About:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 600),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
