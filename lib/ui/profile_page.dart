import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:message/utilities/image_utilies.dart';
import 'package:message/widget/property_view.dart';

class ProfilePage extends StatefulWidget {
  static const routeName = '/profile';
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late DocumentReference<Map<String, dynamic>> _userRef;
  Map<String, dynamic>? _user;
  bool _uploading = false;
  double? _uploadValue;
  File? pickedImage;

  @override
  void initState() {
    super.initState();
    _userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.phoneNumber);
    _reloadData();
  }

  void _reloadData() {
    _userRef.get().then((value) {
      if (mounted) {
        setState(() {
          _user = value.data();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            TextButton(
              child: const Text('Sign out'),
              onPressed: () async {
                log('logout', name: runtimeType.toString());
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.of(context).pushReplacementNamed('/');
              },
            ),
          ],
        ),
        body: _user == null
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 200,
                      width: 200,
                      child: GestureDetector(
                        onTap: () async {
                          Map data = _user!['image'];
                          pickedImage = await ImageUtilities.pickImage(context);
                          if (pickedImage == null) return;
                          setState(() {
                            _uploading = true;
                            _uploadValue = null;
                          });
                          var uploadData = await ImageUtilities.uploadImage(
                            imageFile: pickedImage!,
                            fileName: FirebaseAuth.instance.currentUser!.uid +
                                '_' +
                                pickedImage!.path.split('/').last,
                            onSnapshot: (snapshot) {
                              setState(() {
                                _uploadValue = snapshot.bytesTransferred /
                                    snapshot.totalBytes;
                              });
                              log(
                                'value: $_uploadValue, state: ${snapshot.state}',
                                name: '_uploadImage',
                              );
                            },
                          );
                          if (uploadData == null) {
                            setState(() {
                              _uploading = false;
                            });
                            return;
                          }
                          await _userRef.update({
                            'image': uploadData,
                          });
                          _uploading = false;
                          _uploadValue = null;
                          pickedImage = null;
                          _reloadData();
                          if (data['path'] != null &&
                              data['path'] != uploadData['path']) {
                            FirebaseStorage.instance
                                .ref()
                                .child(data['path'])
                                .delete();
                          }
                        },
                        child: CircleAvatar(
                          backgroundImage: _uploading
                              ? FileImage(pickedImage!)
                              : _user!['image']?['url'] == null
                                  ? const AssetImage(
                                      'assets/images/profile.png')
                                  : NetworkImage(_user!['image']?['url'])
                                      as ImageProvider,
                          child: _uploading
                              ? CircularProgressIndicator(
                                  value: _uploadValue,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding:
                        const EdgeInsets.only(left: 75, right: 75, top: 30),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          PropertyView(
                            label: 'Name',
                            value: '${_user?['name']}',
                            onSubmit: (value) {
                              _userRef.update({
                                'name': value,
                              }).then((_) {
                                _reloadData();
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          PropertyView(
                            label: 'Phone',
                            value: '${_user?['phone']}',
                            editable: false,
                          ),
                          const SizedBox(height: 8),
                          PropertyView(
                            label: 'Description',
                            value: '${_user?['description'] ?? '-'}',
                            onSubmit: (value) {
                              _userRef.update({
                                'description': value,
                              }).then((_) {
                                _reloadData();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
