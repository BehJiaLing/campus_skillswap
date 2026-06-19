import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'profile_edit_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> uploadProfileImage() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) return;

    Uint8List bytes = await image.readAsBytes();

    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child('$uid.jpg');

    await ref.putData(bytes);

    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({
      'photoUrl': url,
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(


      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data =
          snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                const Text(
                  "My Profile",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  "Manage your skills",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1E8),

                    borderRadius:
                    BorderRadius.circular(25),

                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(20),

                    child: Column(
                      children: [

                        Row(
                          children: [

                            GestureDetector(
                              onTap: uploadProfileImage,
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor: const Color(0xFF6D718B),
                                backgroundImage:
                                data['photoUrl'] != ''
                                    ? NetworkImage(data['photoUrl'])
                                    : null,
                                child:
                                data['photoUrl'] == ''
                                    ? const Icon(
                                  Icons.person,
                                  size: 45,
                                  color: Colors.white,
                                )
                                    : null,
                              ),
                            ),

                            const SizedBox(width: 15),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,

                                children: [

                                  Text(
                                    data['name'] ?? '',
                                    style:
                                    const TextStyle(
                                      fontSize: 20,
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),

                                  Text(
                                    data['course'] ?? '',
                                  ),

                                  Text(
                                    data['school'] ?? '',
                                  ),

                                  const SizedBox(
                                      height: 5),

                                  Text(
                                    "Skills: ${((data['skills'] ?? []) as List).join(', ')}",
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),

                              child: IconButton(
                                icon: const Icon(Icons.edit),

                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                      const ProfileEditPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .spaceEvenly,

                          children: [

                            statBox(
                              "0",
                              "Posts",
                              Icons.article,
                            ),

                            statBox(
                              "0.0",
                              "Rating",
                              Icons.star,
                            ),

                            statBox(
                              "0",
                              "Points",
                              Icons.workspace_premium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1E8),

                    borderRadius:
                    BorderRadius.circular(20),

                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                      ),
                    ],
                  ),

                  child: ListTile(
                    leading:
                    const Icon(Icons.settings),

                    title:
                    const Text("Settings"),

                    trailing:
                    const Icon(Icons.chevron_right),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const SettingsPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget statBox(
      String value,
      String label,
      IconData icon,
      ) {
    return Container(
      width: 90,
      height: 100,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(15),
      ),

      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,

        children: [

          Icon(
            icon,
            color: const Color(0xFF6D718B),
          ),

          const SizedBox(height: 5),

          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(label),
        ],
      ),
    );
  }
}