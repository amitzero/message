import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:message/ui/contacts_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  File? pickedImage;
  final _nameController = TextEditingController(text: 'Redmi');
  final _numberController = TextEditingController(text: '1763010362');
  final _verificationCodeController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _verificationFormKey = GlobalKey<FormState>();
  bool _verifyOTP = false;
  bool _isLoading = false;
  bool _isConfirming = false;
  String _verificationId = '';

  @override
  void initState() {
    super.initState();
    _auth.currentUser != null
        ? Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) {
                return const ContactsPage();
              },
            ),
          )
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Join Message',
            style: TextStyle(fontSize: 30),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width / 1.5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_verifyOTP) ...[
                Form(
                  key: _verificationFormKey,
                  child: Column(
                    children: [
                      TextFormField(
                        style: const TextStyle(fontSize: 30),
                        controller: _verificationCodeController,
                        decoration: InputDecoration(
                          labelText: 'OTP',
                          helperText: 'Enter the OTP sent to your phone',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                _verificationCodeController.clear(),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(6),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (_verificationCodeController.text.length != 6) {
                            return 'Invalid OTP';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _isConfirming
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_verificationFormKey.currentState
                                          ?.validate() ??
                                      false) {
                                    _verify();
                                  }
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    'Confirm',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ] else ...[
                //Profile Image
                GestureDetector(
                  onTap: () async {
                    // // show bottom dialog to select image source
                    // final source = await showModalBottomSheet(
                    //   context: context,
                    //   builder: (_) => SizedBox(
                    //     height: 200,
                    //     width: MediaQuery.of(context).size.width - 200,
                    //     child: Column(
                    //       mainAxisAlignment: MainAxisAlignment.center,
                    //       children: [
                    //         const Text(
                    //           'Select Image Source',
                    //           style: TextStyle(fontSize: 30),
                    //         ),
                    //         const SizedBox(height: 20),
                    //         SizedBox(
                    //           width: MediaQuery.of(context).size.width / 2,
                    //           child: ElevatedButton(
                    //             child: const ListTile(
                    //               leading: Icon(Icons.camera_alt),
                    //               title: Text(
                    //                 'Camera',
                    //                 style: TextStyle(fontSize: 20),
                    //               ),
                    //             ),
                    //             onPressed: () {
                    //               Navigator.pop(context, ImageSource.camera);
                    //             },
                    //           ),
                    //         ),
                    //         const SizedBox(height: 10),
                    //         SizedBox(
                    //           width: MediaQuery.of(context).size.width / 2,
                    //           child: ElevatedButton(
                    //             child: const ListTile(
                    //               leading: Icon(Icons.photo_library),
                    //               title: Text(
                    //                 'Gallery',
                    //                 style: TextStyle(fontSize: 20),
                    //               ),
                    //             ),
                    //             onPressed: () {
                    //               Navigator.pop(context, ImageSource.gallery);
                    //             },
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // );
                    // if (source == null) return;
                    // var imageFile = await ImagePicker().pickImage(
                    //   source: source,
                    // );
                    // if (imageFile != null) {
                    //   log('${imageFile.name}:${imageFile.mimeType}',
                    //       name: 'image selected');
                    //   pickedImage = File(imageFile.path);
                    //   log(pickedImage!.path, name: 'pickedImage');
                    //   setState(() {});
                    // }
                    try {
                      var filePickerResult =
                          await FilePicker.platform.pickFiles(
                        dialogTitle: 'Select Profile Image',
                        type: FileType.image,
                        onFileLoading: (status) {
                          log('$status', name: 'file loading');
                        },
                      );
                      log('$filePickerResult', name: 'filePickerResult');
                      setState(() {
                        pickedImage = filePickerResult == null
                            ? null
                            : File(filePickerResult.files.single.path!);
                      });
                    } on PlatformException catch (e) {
                      log('Unsupported operation' + e.toString());
                    } catch (e) {
                      log(e.toString());
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: pickedImage != null
                          ? DecorationImage(
                              image: FileImage(pickedImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: pickedImage != null
                        ? null
                        : const Icon(
                            Icons.add_a_photo,
                            size: 100,
                          ),
                  ),
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(30),
                        ],
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _numberController,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          border: OutlineInputBorder(),
                          prefixText: '+880',
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(10),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (_numberController.text.length != 10) {
                            return 'Invalid phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState?.validate() ??
                                      false) {
                                    _login();
                                  }
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    'Login',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, String>?> _uploadImage() async {
    if (pickedImage == null) return null;
    final ref = FirebaseStorage.instance
        .ref()
        .child('users_profiler_pictures/${pickedImage!.path.split('/').last}');
    final uploadTask = ref.putFile(pickedImage!);
    await for (final snapshot in uploadTask.snapshotEvents) {
      log(
        '${snapshot.bytesTransferred / snapshot.totalBytes * 100}%',
        name: 'snapshot',
      );
      log('$snapshot', name: 'snapshot');
      if (snapshot.state == TaskState.success) {
        return {
          'fulPath': snapshot.ref.fullPath,
          'url': await snapshot.ref.getDownloadURL(),
        };
      } else if (snapshot.state == TaskState.error) {
        log(snapshot.state.toString(), name: 'snapshot error');
        return null;
      }
    }
    return null;
  }

  void _nextPage() async {
    await _auth.currentUser!.updateDisplayName(_nameController.text);
    var token = await FirebaseMessaging.instance.getToken();
    var uploadedMetadata = await _uploadImage();
    await FirebaseFirestore.instance
        .doc('users/${_auth.currentUser!.phoneNumber}')
        .set({
      'token': token,
      'name': _nameController.text,
      'uid': _auth.currentUser!.uid,
      'phone': _auth.currentUser!.phoneNumber,
      'image': uploadedMetadata,
    });

    Navigator.pushReplacementNamed(context, '/');
  }

  void _verify() async {
    log('Verify', name: 'Verify');
    setState(() {
      _isConfirming = true;
    });
    var smsCode = _verificationCodeController.text;
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId,
      smsCode: smsCode,
    );
    try {
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      log('signInWithCredential: $e', name: '_phoneAuth');
    }
    if (_auth.currentUser != null) {
      _nextPage();
    } else {
      setState(() {
        _verifyOTP = false;
      });
    }
  }

  void _login() async {
    log(
      'name: ${_nameController.text}, number: ${_numberController.text}',
      name: 'Login',
    );
    setState(() {
      _isLoading = true;
    });
    _phoneAuth('+880${_numberController.text}');
  }

  Future<void> _phoneAuth(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (phoneAuthCredential) async {
          log(
            'verificationCompleted: ${phoneAuthCredential.toString()}',
            name: '_phoneAuth',
          );
          await _auth.signInWithCredential(phoneAuthCredential);
          if (_auth.currentUser != null) {
            _nextPage();
          } else {
            setState(() {
              _isLoading = false;
              _verifyOTP = false;
            });
          }
        },
        verificationFailed: (firebaseAuthException) {
          log('verificationFailed: $firebaseAuthException', name: '_phoneAuth');
          setState(() {
            _isLoading = false;
            _verifyOTP = false;
          });
        },
        codeSent: (String verificationId, int? resendToken) async {
          log('codeSent: $verificationId, $resendToken', name: '_phoneAuth');
          setState(() {
            _isLoading = false;
            _verifyOTP = true;
            _isConfirming = false;
            _verificationId = verificationId;
          });
        },
        codeAutoRetrievalTimeout: (e) {
          log('codeAutoRetrievalTimeout: $e', name: '_phoneAuth');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _verifyOTP = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OTP Timeout. Please try again.'),
              ),
            );
          }
        },
      );
    } catch (e) {
      log('error: $e', name: '_phoneAuth');
    }
  }
}
