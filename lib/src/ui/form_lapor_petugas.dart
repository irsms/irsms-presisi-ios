import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_irsms/src/ui/lapor_laka.dart';
import 'package:flutter_application_irsms/src/ui/pengaduan.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../libraries/colors.dart' as my_colors;
import '../services/rest_client.dart';
import 'card_picture.dart';

class LaporPetugas extends StatefulWidget {
  const LaporPetugas({super.key});

  @override
  State<LaporPetugas> createState() => _LaporPetugasState();
}

class _LaporPetugasState extends State<LaporPetugas> {
  final _formKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();
  File? _image;
  List<String> get _imagePaths => [_image!.path];

  bool isLoading = false;

  String _token = '';

  Map<String, dynamic> _polres = {};

  final TextEditingController _roadNameController = TextEditingController();
  final TextEditingController _satuanKepolisianController =
      TextEditingController();
  final TextEditingController _mdController = TextEditingController();
  final TextEditingController _lbController = TextEditingController();
  final TextEditingController _lrController = TextEditingController();
  final TextEditingController _cronologicalController = TextEditingController();

  void _submit() async {
    setState(() {
      isLoading = true;
    });

    var profile =
        await RestClient().get(controller: 'petugas/profile', params: {
      'token': _token,
    });

    if (profile['status']) {
      var resp = await RestClient().uploadPhotos(_imagePaths);

      if (resp['status']) {
        String fileName = resp['rows'][0]['file_name'];

        // DateTime now = DateTime.now();
        // var epochTime = now.microsecondsSinceEpoch;
        Map<String, dynamic> data = {
          'picture': "uploads/$fileName",
          'road_name': _roadNameController.text,
          'satuan_kepolisian': _satuanKepolisianController.text,
          'md': _mdController.text,
          'lb': _lbController.text,
          'lr': _lrController.text,
          'chronological': _cronologicalController.text,
          'accident_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'accident_time': DateFormat('HH:mm').format(DateTime.now()),
          'users_id': profile['rows'][0]['id']
        };

        String controller = 'petugas/lapor_laka';

        var postResp = await RestClient()
            .post(token: _token, controller: controller, data: data);

        print(postResp);

        isLoading = false;
        setState(() {});

        if (postResp['status']) {
          await Future.delayed(const Duration(seconds: 3));
          if (!mounted) return;
          // Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(
              builder: (BuildContext context) => const LaporLaka(),
            ),
          );

          // Navigator.push(context,
          //     MaterialPageRoute(builder: ((context) => const LaporLaka())));
        } else {
          _showDialog(postResp);
        }
      } else {
        _showDialog(resp);
      }
    } else {
      setState(() {
        isLoading = false;
      });
      _showDialog(profile);
    }
  }

  void _showDialog(Map<String, dynamic> err) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('IRSMS'),
              content: Text(Bidi.stripHtmlIfNeeded(err['error']).trim()),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isLoading = false;
                      });

                      if (err['error'] == 'Expired token') {
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
  void initState() {
    Future.delayed(Duration.zero, () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token') ?? '';

      var controller = 'polres';
      var params = {'token': _token};
      _polres = await RestClient().get(controller: controller, params: params);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Lapor'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: CardPicture(
                    onTap: () async {
                      XFile? xFile = await _picker.pickImage(
                          source: ImageSource.camera,
                          maxWidth: 300,
                          maxHeight: 300);

                      if (xFile != null) {
                        _image = File(xFile.path);
                        _imagePaths.add(_image!.path);

                        setState(() {});
                      }
                    },
                    imagePath: _image?.path,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                const Text(
                  'Nama Jalan',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: my_colors.blue, fontWeight: FontWeight.bold),
                ),
                TextFormField(
                  controller: _roadNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.only(
                        top: 0, right: 30, bottom: 0, left: 15),
                    hintText: 'Masukkan di Sini',
                  ),
                  autovalidateMode: AutovalidateMode.always,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '* wajib diisi';
                    }

                    return null;
                  },
                ),
                const SizedBox(
                  height: 16.0,
                ),
                const Text(
                  'Polres/Polda',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: my_colors.blue, fontWeight: FontWeight.bold),
                ),
                TypeAheadFormField(
                  textFieldConfiguration: TextFieldConfiguration(
                    controller: _satuanKepolisianController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.only(
                          top: 0, right: 30, bottom: 0, left: 16),
                      hintText: 'Masukkan di Sini',
                    ),
                  ),
                  onSuggestionSelected: ((suggestion) {
                    _satuanKepolisianController.text = suggestion.toString();
                  }),
                  itemBuilder: ((context, itemData) {
                    return ListTile(
                      title: Text(itemData.toString()),
                    );
                  }),
                  suggestionsCallback: (pattern) async {
                    List<String> polres = [];
                    if (_polres['total'] != 0) {
                      _polres['rows'].forEach((item) {
                        if (RegExp(pattern).hasMatch(item['name'])) {
                          polres.add(item['name']);
                        }
                      });
                    }

                    return polres;
                  },
                  autovalidateMode: AutovalidateMode.always,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '* wajib diisi';
                    }

                    return null;
                  },
                ),
                const SizedBox(
                  height: 16.0,
                ),
                const Text(
                  'Jumlah Korban',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: my_colors.blue, fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Expanded(child: Text('Meninggal Dunia')),
                    Expanded(
                      child: TextFormField(
                        controller: _mdController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.only(
                              top: 0, right: 30, bottom: 0, left: 15),
                          hintText: 'Masukkan di Sini',
                        ),
                        autovalidateMode: AutovalidateMode.always,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '* wajib diisi';
                          }

                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 16.0,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Expanded(child: Text('Luka Berat')),
                    Expanded(
                      child: TextFormField(
                        controller: _lbController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.only(
                              top: 0, right: 30, bottom: 0, left: 15),
                          hintText: 'Masukkan di Sini',
                        ),
                        autovalidateMode: AutovalidateMode.always,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '* wajib diisi';
                          }

                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 16.0,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Expanded(child: Text('Luka Ringan')),
                    Expanded(
                      child: TextFormField(
                        controller: _lrController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.only(
                              top: 0, right: 30, bottom: 0, left: 15),
                          hintText: 'Masukkan di Sini',
                        ),
                        autovalidateMode: AutovalidateMode.always,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '* wajib diisi';
                          }

                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 16.0,
                ),
                const Text(
                  'Kronologis Singkat',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: my_colors.blue, fontWeight: FontWeight.bold),
                ),
                TextFormField(
                  controller: _cronologicalController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.only(
                        top: 0, right: 30, bottom: 0, left: 15),
                    hintText: 'Masukkan di Sini',
                  ),
                  autovalidateMode: AutovalidateMode.always,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '* wajib diisi';
                    }

                    return null;
                  },
                ),
                const SizedBox(
                  height: 16.0,
                ),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_image == null) {
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                    title: const Text('IRSMS'),
                                    content:
                                        const Text('Gambar belum diambil.'),
                                    actions: [
                                      ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Tutup'))
                                    ],
                                  ));
                        } else if (_formKey.currentState!.validate() &&
                            !isLoading) {
                          _submit();
                        }
                      },
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(my_colors.blue),
                        padding:
                            MaterialStateProperty.all(const EdgeInsets.all(16)),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                      child: (isLoading)
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 1.5,
                              ),
                            )
                          : const Text(
                              'Kirim',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                    )),
              ],
            ),
          ),
        )),
      ),
    );
  }
}
