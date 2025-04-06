import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_irsms/src/models/accident.dart';
import 'package:flutter_application_irsms/src/services/rest_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class PencarianLP extends StatefulWidget {
  const PencarianLP({super.key});

  @override
  State<PencarianLP> createState() => _PencarianLPState();
}

class _PencarianLPState extends State<PencarianLP> {
  final _formKey = GlobalKey<FormState>();

  List<Accident> daftarLp = [];

  String _token = '';

  final TextEditingController _searchController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token') ?? '';
    });

    super.initState();
  }

  void _alertDialog(Map<String, dynamic> data) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('IRSMS'),
              content: Text(data['error'].toString()),
              actions: [
                TextButton(
                    onPressed: () {
                      if (data['error'] == 'Expired token') {
                        Navigator.pushNamed(context, '/');
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Tutup'))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencarian Laporan LP'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: TextFormField(
                      key: const Key('s'),
                      controller: _searchController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Ketik Nomor LP di sini',
                        contentPadding: const EdgeInsets.only(
                            top: 0, right: 30, bottom: 0, left: 15),
                        suffixIcon: GestureDetector(
                          onTap: () async {
                            if (_formKey.currentState!.validate()) {
                              await _submit();
                            }
                          },
                          child: (isLoading)
                              ? const Center(
                                  child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator()),
                                )
                              : const Icon(
                                  Icons.search,
                                  size: 30,
                                ),
                        ),
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: ((value) {
                        if (value == null || value.isEmpty) {
                          return "* wajib diisi";
                        }

                        return null;
                      }),
                    ),
                  ),
                  const SizedBox(
                    height: 16.0,
                  ),
                  SingleChildScrollView(
                    child: daftarLp.isEmpty
                        ? const Column(
                            children: [Text('Tidak Ada Data')],
                          )
                        : Column(
                            children: daftarLp.map((accident) {
                              return ListTile(
                                title: Text(accident.noLp),
                                subtitle: Text(
                                    "Tanggal Kejadian : ${accident.accidentDate}"),
                                onTap: () async {
                                  final url =
                                      "https://irsms.korlantas.polri.go.id/cetak_bpjs_android/cetak?id=${accident.id}"; // Replace with your URL
                                  // ignore: deprecated_member_use
                                  if (await canLaunch(url)) {
                                    // ignore: deprecated_member_use
                                    await launch(url);
                                  } else {
                                    throw 'Could not launch $url';
                                  }
                                },
                                // Add more details as needed
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<List<Accident>> _submit() async {
    setState(() {
      isLoading = true;
    });

    var controller = 'masyarakat/pencarian_lp';
    var params = {
      'token': _token,
      'search': _searchController.text,
      // 'start': tanggalAwal.toString().substring(0, 10),
      // 'end': tanggalAkhir.toString().substring(0, 10),
      // 'polda': polda,
      // 'polres': polres
    };
    var resp = await RestClient().get(controller: controller, params: params);

    if (resp['status']) {
      daftarLp.clear();
      resp['rows'].forEach((row) {
        daftarLp.add(Accident(
            id: row['id'],
            noLp: row['no_lp'],
            namaJalan: row['road_name'],
            accidentDate: row['accident_date'],
            accidentTime: row['accident_time'],
            reportDate: row['report_date'],
            reportTime: row['report_time'],
            md: row['md'],
            lb: row['lb'],
            lr: row['lr'],
            dorsId: row['dors_id']));
      });

      setState(() {});
    } else {
      _alertDialog(resp);
    }

    setState(() {
      isLoading = false;
    });

    return daftarLp;
  }

  //Widget terpisah untuk dimasukan pada Widget build

  // Widget _buildAccidentList() {
  //   if (daftarLp.isEmpty) {
  //     return const Center(
  //       child: Text("Laporan LP Tidak ditemukan"),
  //     );
  //   } else {
  //     return ListView.builder(
  //       itemCount: daftarLp.length,
  //       itemBuilder: (BuildContext context, int index) {
  //         Accident accident = daftarLp[index];
  //         return ListTile(
  //           title: Text("No LP: ${accident.noLp}"),
  //           subtitle: Text("Date: ${accident.accidentDate}"),
  //           // Add more details as needed
  //           onTap: () {
  //             // Handle the onTap event for each item if needed
  //           },
  //         );
  //       },
  //     );
  //   }
  // }
}
