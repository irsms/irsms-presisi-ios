import 'package:flutter_application_irsms/main.dart';
import 'package:flutter_application_irsms/src/ui/reset_password.dart';
import 'package:flutter_application_irsms/src/ui/reset_password_profile.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../libraries/colors.dart' as my_colors;
import '../services/rest_client.dart';
import 'profil_edit.dart';

class Profil extends StatefulWidget {
  const Profil({super.key});

  @override
  State<Profil> createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {
  Map<String, dynamic> _profile = <String, dynamic>{};

  late String _token;

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token') ?? '';

      await _getProfile();
    });

    super.initState();
  }

  Future<void> _getProfile() async {
    var controller = 'masyarakat/profile';
    var params = {'token': _token};
    Map<String, dynamic> profile =
        await RestClient().get(controller: controller, params: params);

    if (profile['status']) {
      setState(() {
        _profile = profile['rows'][0];
      });
    } else {
      if (!mounted) return;

      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('IRSMS'),
                content: Text(profile['error']),
                actions: [
                  TextButton(
                      onPressed: () {
                        if (_profile['error'] == 'Expired token') {
                          Navigator.pushNamed(context, '/');
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Tutup'))
                ],
              ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _onWillPop();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 16.0,
            ),
            Center(
              child: InkWell(
                onTap: _setAvatar,
                child: CircleAvatar(
                  radius: MediaQuery.of(context).size.width * .1,
                  child: FutureBuilder<http.Response>(
                    future: http.get(Uri.parse(
                        '${RestClient().baseURL}/${_profile["userpic"]}')),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.none:
                          return const Icon(
                            Icons.person,
                            size: 128,
                          );
                        case ConnectionState.active:
                        case ConnectionState.waiting:
                          return const CircularProgressIndicator();
                        case ConnectionState.done:
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          if (snapshot.data!.statusCode == 200) {
                            return SizedBox(
                                width: MediaQuery.of(context).size.width,
                                height:
                                    MediaQuery.of(context).size.width * 0.5625,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(128),
                                  child: Image.memory(
                                    snapshot.data!.bodyBytes,
                                    width: 128,
                                    height: 128,
                                    fit: BoxFit.cover,
                                  ),
                                ));
                          }

                          return const Icon(
                            Icons.person,
                            size: 50,
                            color: my_colors.yellow,
                          );
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 16.0,
            ),
            Text(
              "${_profile['nama_depan'] ?? ''} ${_profile['nama_belakang'] ?? ''}",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 5.0,
            ),
            Text(
              _profile['email'] ?? '',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(
              height: 16.0,
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Nama Lengkap'),
                      subtitle: Text(
                        "${_profile['nama_depan'] ?? ''} ${_profile['nama_belakang'] ?? ''}",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.credit_card),
                      title: const Text('NIK'),
                      subtitle: Text(
                        _profile['nik'] ?? '',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text('No. HP'),
                      subtitle: Text(
                        _profile['no_hp'] ?? '',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Email'),
                      subtitle: Text(
                        _profile['email'] ?? '',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: const Text('Alamat'),
                      subtitle: Text(
                        _profile['alamat'] ?? '',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 5.0,
            ),
            Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                elevation: 4,
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              // Add your onTap logic here
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ProfilEdit()));
                            },
                            child: const ListTile(
                              leading: Icon(Icons.settings),
                              title: Text('Edit Profile'),
                              // subtitle: Text(
                              //   _profile['alamat'] ?? '',
                              //   style: TextStyle(color: Colors.grey[700]),
                              // ),
                              trailing: Icon(Icons.arrow_forward_ios),
                            ),
                          ),
                          const Divider(),
                          InkWell(
                            onTap: () {
                              // Add your onTap logic here
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ResetPasswordProfile()));
                            },
                            child: const ListTile(
                              leading: Icon(Icons.shield),
                              title: Text('Reset Password'),
                              // subtitle: Text(
                              //   _profile['alamat'] ?? '',
                              //   style: TextStyle(color: Colors.grey[700]),
                              // ),
                              trailing: Icon(Icons.arrow_forward_ios),
                            ),
                          )
                        ]))),
            const SizedBox(
              height: 16.0,
            ),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //   children: [
            //     ElevatedButton(
            //       onPressed: () {
            //         Navigator.push(
            //             context,
            //             MaterialPageRoute(
            //                 builder: (context) => const ProfilEdit()));
            //       },
            //       child: const Text('Edit Profile'),
            //     ),
            //     ElevatedButton(
            //       onPressed: () {
            //         Navigator.push(
            //             context,
            //             MaterialPageRoute(
            //                 builder: (context) => const ProfilEdit()));
            //       },
            //       child: const Text('Reset Password'),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(String source) async {
    final ImagePicker picker = ImagePicker();
    File? image;

    XFile? xFile = await picker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300);

    if (xFile != null) {
      image = File(xFile.path);

      var resp =
          await RestClient().uploadAvatar(path: image.path, token: _token);

      if (resp['status'] == false) {
        if (!mounted) return;

        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('IRSMS'),
                  content: Text(resp['error'].toString()),
                  actions: [
                    TextButton(
                        onPressed: () {
                          if (resp['error'] == 'Expired token') {
                            Navigator.pushNamed(context, '/');
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('Tutup'))
                  ],
                ));
      } else {
        var controller = 'masyarakat/profile';
        var params = {'token': _token};
        Map<String, dynamic> profile =
            await RestClient().get(controller: controller, params: params);

        setState(() {
          _profile = profile['rows'][0];
        });
      }
    }
  }

  void _setAvatar() {
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(8.0))),
        context: context,
        isScrollControlled: true,
        builder: (context) => Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _pickImage('camera');
                        },
                        child: const Text('Kamera')),
                    ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _pickImage('gallery');
                        },
                        child: const Text('Galeri')),
                  ],
                ),
              ),
            ));
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('token');
    prefs.remove('_idResgister');
    // ignore: use_build_context_synchronously
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (context) => const MyHomePage(
                title: 'IRSMS',
              )),
      (route) => false,
    );
    // }
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('Anda yakin?'),
                  content: const Text('Anda ingin keluar ?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Tidak')),
                    TextButton(
                        onPressed: () => logout(), child: const Text('Ya')),
                  ],
                ))) ??
        false;
  }
}
