import 'package:flutter/material.dart';
import 'package:flutter_application_irsms/src/ui/lapor_laka_petugas.dart';
import 'package:http/http.dart' as http;
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../libraries/colors.dart' as my_colors;
import '../services/rest_client.dart';
import '../models/laka_model_petugas.dart';

class LaporDetailPetugas extends StatefulWidget {
  final LakaModelPetugas? lakaModelPetugas;
  const LaporDetailPetugas({this.lakaModelPetugas, super.key});

  @override
  State<LaporDetailPetugas> createState() => _LaporDetailPetugasState();
}

class _LaporDetailPetugasState extends State<LaporDetailPetugas> {
  final TextEditingController _cronologicalController = TextEditingController();

  String? _category;
  String? _statuslaka;

  bool isLoading = false;

  String? _token;

  final List<String> _categories = [];

  Future<void> fetchCategories() async {
    var controller = 'accident_category';
    var params = {'token': _token};
    var resp = await RestClient().get(controller: controller, params: params);
    if (resp['status']) {
      resp['rows'].forEach((row) => _categories.add(row['accident_category']));
    }
  }

  @override
  void initState() {
    _category = widget.lakaModelPetugas!.kategori;
    _statuslaka = widget.lakaModelPetugas!.statusLaporan;
    _cronologicalController.text = widget.lakaModelPetugas!.deskripsi;

    Future.delayed(Duration.zero, () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token') ?? '';
      await fetchCategories();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Lapor Detail"),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FutureBuilder(
              future: http.get(Uri.parse(widget.lakaModelPetugas!.gambar)),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                    return const Text('Tidak ada gambar');
                  case ConnectionState.active:
                  case ConnectionState.waiting:
                    return const CircularProgressIndicator();
                  case ConnectionState.done:
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    return SizedBox(
                      width: MediaQuery.of(context).size.height * .5,
                      //    child: Image.memory(
                      //  snapshot.data!.bodyBytes,
                      //  fit: BoxFit.fitWidth,
                      //   ),
                    );
                }
              },
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nama Jalan',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(widget.lakaModelPetugas!.namaJalan.toString()),
                  const SizedBox(
                    height: 16,
                  ),
                  const Text(
                    'Polres / Poldaa',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(widget.lakaModelPetugas!.pelaksanaTugas.toString()),
                  const SizedBox(
                    height: 16,
                  ),
                  // const Text(
                  //   'Petugas Pelapor',
                  //   style: TextStyle(color: Colors.grey),
                  // ),
                  // Text(widget.lakaModel!.petugasPelapor.toString()),
                  // const SizedBox(
                  //   height: 16,
                  // ),
                  // const Text(
                  //   'Jumlah Korban',
                  //   style: TextStyle(color: Colors.grey),
                  // ),
                  // Text(widget.lakaModel!.jumlahKorban.toString()),
                  // const SizedBox(
                  //   height: 16,
                  // ),
                  Center(
                    child: ElevatedButton(
                      onPressed: _formDeskripsi,
                      child: const Text(
                        'Lengkapi Laporan',
                        style: TextStyle(
                            color: my_colors.blue, fontWeight: FontWeight.bold),
                      ),
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

  void _formDeskripsi() {
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
        constraints:
            BoxConstraints(maxWidth: 0.9 * MediaQuery.of(context).size.width),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.0))),
        context: context,
        isScrollControlled: true,
        builder: (builder) {
          return Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                height: 16,
                              ),
                              const Text(
                                'Kategori',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    color: my_colors.blue,
                                    fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: DropdownButtonFormField<String>(
                                  value: _category,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  isExpanded: true,
                                  hint: const Text('Pilih Kategori Laporan'),
                                  items: _categories
                                      .map((e) => DropdownMenuItem<String>(
                                            value: e,
                                            child: Text(e),
                                          ))
                                      .toList(),
                                  autovalidateMode: AutovalidateMode.always,
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Silahkan pilih kategori';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      _category = value as String?;
                                    });
                                  },
                                  onSaved: (newValue) {
                                    _category = newValue as String?;
                                  },
                                ),
                              ),
                              const Text(
                                'Deskripsi',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    color: my_colors.blue,
                                    fontWeight: FontWeight.bold),
                              ),
                              TextFormField(
                                controller: _cronologicalController,
                                autovalidateMode: AutovalidateMode.always,
                                validator: (value) {
                                  if (value == "") {
                                    return '* wajib diisi.';
                                  }
                                  return null;
                                },
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
                              ),
                              Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (formKey.currentState!.validate()) {
                                        _submit();
                                      }
                                    },
                                    style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all(
                                              my_colors.blue),
                                      padding: MaterialStateProperty.all(
                                          const EdgeInsets.all(16)),
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
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
  }

  void _submit() async {
    setState(() {
      isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var controller = 'petugas/lapor_laka';
    var params = {
      'token': prefs.getString('token'),
      'petugas__lapor_laka_id': widget.lakaModelPetugas!.id
    };

    if (_category == 'Data Tidak Sah') {
      _statuslaka = '0';
    } else if (_category == 'Selesai') {
      _statuslaka = '9';
    } else {
      _statuslaka = '1';
    }

    var data = {
      'category': _category,
      'status_laporan': _statuslaka,
      'chronological': _cronologicalController.text
    };

    var resp = await RestClient()
        .put(controller: controller, params: params, data: data);
    if (mounted && resp['status'] == false) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('IRSMS'),
                content: Text(resp['error']),
                actions: [
                  ElevatedButton(
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
    }

    setState(() {
      isLoading = false;
    });
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const LaporLakaPetugas()));
  }
}
