import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_irsms/main.dart';

import '../services/rest_client_petugas.dart';

class ProfilPetugas extends StatefulWidget {
  const ProfilPetugas({super.key});

  @override
  State<ProfilPetugas> createState() => _ProfilState();
}

class _ProfilState extends State<ProfilPetugas> {
  Map<String, dynamic> _profile = <String, dynamic>{};

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('token') ?? '';
      var controller = 'petugas/profile';
      var params = {'token': token};
      Map<String, dynamic> profile =
          await RestClientPetugas().get(controller: controller, params: params);

      if (profile['status']) {
        _profile = profile['rows'][0];
        setState(() {});
      } else if (mounted) {
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
    });

    super.initState();
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
          child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                radius: MediaQuery.of(context).size.width * .25,
                child: const Icon(
                  Icons.local_police,
                  size: 128,
                ),
                //   child: FutureBuilder(
                //         future: http.get(Uri.parse(
                //             '${RestClient().baseURL}/${_profile["image"]}')),
                //         builder: (context, snapshot) {
                //           switch (snapshot.connectionState) {
                //             case ConnectionState.none:
                //               return const Icon(
                //                 Icons.person,
                //                 size: 128,
                //               );
                //             case ConnectionState.active:
                //             case ConnectionState.waiting:
                //               return const CircularProgressIndicator();
                //             case ConnectionState.done:
                //               if (snapshot.hasError) {
                //                 return Text('Error: ${snapshot.error}');
                //               }
                //               return SizedBox(
                //                   width: MediaQuery.of(context).size.width,
                //                   height:
                //                       MediaQuery.of(context).size.width * 0.5625,
                //                   child: ClipRRect(
                //                     borderRadius: BorderRadius.circular(128),
                //                     child: Image.network(
                //                       '${RestClient().baseURL}/${_profile["image"]}',
                //                       width: 128,
                //                       height: 128,
                //                       fit: BoxFit.cover,
                //                     ),
                //                   ));
                //           }
                //         },
                //       ),
              ),
            ),
            const SizedBox(
              height: 16.0,
            ),
            SizedBox(
              width: double.infinity,
              child: Card(
                elevation: 10,
                child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NAMA',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _profile['first_name'] ?? '',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(
                            height: 16.0,
                          ),
                          const Text(
                            'NRP',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _profile['officer_id'] ?? '',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(
                            height: 16.0,
                          ),
                          const Text(
                            'NO. HP',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _profile['phone_number'] ?? '',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(
                            height: 16.0,
                          ),
                          const Text(
                            'EMAIL',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _profile['email'] ?? '',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(
                            height: 16.0,
                          ),
                        ],
                      ),
                    )),
              ),
            )
          ],
        ),
      )),
    );
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
