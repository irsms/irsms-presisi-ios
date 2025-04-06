// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/dbhelper.dart';
import '../models/user_location.dart';
import '../services/realtime_location.dart';
import '../services/rest_client.dart';
import 'daftar_laka.dart';
// import 'package:connectivity/connectivity.dart';
import 'package:path/path.dart' as path;
// import 'form_saksi.dart';

class TambahData extends StatefulWidget {
  final String accidentUuid;
  final Map<String, dynamic>? accidentData;
  // final File? imageFile;
  // final List<File> images;
  final List<String?> imageUrls;

  //final List<String> get _imagePaths => [modifiedImage!.path];

  const TambahData({
    Key? key,
    //  required this.imageFile,
    required this.accidentUuid,
    // required this.images,
    required this.imageUrls,
    this.accidentData,
  }) : super(key: key);

  @override
  State<TambahData> createState() => _TambahDataState();
}

class _TambahDataState extends State<TambahData> {
  late Dbhelper _dbhelper;
  List<Map<String, dynamic>> _pictures = [];
  bool _isConnected = false;
  // List<Map<String, dynamic>> _saksi = [];
  File? _image;
  final _formKey = GlobalKey<FormState>();
  final DateTime _timestamp = DateTime.now();
  String _tanggalKejadian = '';
  final String _tanggalKejadiann = '';
  String _tanggalLaporan = '';
  String _jamKejadian = '';
  String _jamLaporan = '';
  List _listLaka = [];
  List _listRef = [];
//  File? _image;
  bool isLoading = false;
  bool loading = true;
  final List<String> _imagePaths = [];

  final List<File?> _files = List<File?>.filled(5, null);

  final _images = [];

  final _petugasPelapor = {
    'nama': '-',
    'nrp': '-',
    'polda': '-',
    'polres': '-'
  };

  String _token = '';
  final Map<String, String> grpID = {
    'informasiKhusus': 'A06',
    'tipeKecalakaan': 'A07',
    'kondisiCahaya': 'A08',
    'cuaca': 'A09',
    'kecelakaanMenonjol': 'A10',
    'kerusakanMaterial': 'PRP1'
  };

  List informasiKhusus = [];
  // final List<String> tipeKecalakaan = [];
  List tipeKecalakaan = [];
  List kondisiCahaya = [];
  List cuaca = [];
  List kecelakaanMenonjol = [];
  List kerusakanMaterial = [];

  Future<void> _fetchReferences() async {
    String controller = 'ref';

    Map<String, String> params = {
      'token': 'Hy6d3K1d93LOHRfbeE0KKly1YK9t4YdGsbNDEvyxAYI=irsmsmobile'
    };
    (grpID.values.toList())
        .asMap()
        .entries
        .forEach((e) => params['grp_id[${e.key}]'] = e.value);

    var resp = await RestClient().get(controller: controller, params: params);
    print(resp['status']);

    if (resp['status']) {
      resp['rows'].forEach((e) {
        if (e['grp_id'] == grpID['kondisiCahaya']) {
          kondisiCahaya
              .add({'value': e['id'], 'title': e['name'], 'isChecked': false});
        } else if (e['grp_id'] == grpID['cuaca']) {
          cuaca.add({'value': e['id'], 'title': e['name'], 'isChecked': false});
        } else if (e['grp_id'] == grpID['informasiKhusus']) {
          informasiKhusus
              .add({'value': e['id'], 'title': e['name'], 'isChecked': false});
        } else if (e['grp_id'] == grpID['tipeKecalakaan']) {
          tipeKecalakaan
              .add({'value': e['id'], 'title': e['name'], 'isChecked': false});
        } else if (e['grp_id'] == grpID['kecelakaanMenonjol']) {
          kecelakaanMenonjol
              .add({'value': e['id'], 'title': e['name'], 'isChecked': false});
        } else if (e['grp_id'] == grpID['kerusakanMaterial']) {
          kerusakanMaterial
              .add({'value': e['id'], 'title': e['name'], 'isChecked': false});
        }
      });
    } else {
      for (var e in _listRef) {
        if (e['grp_id'] == grpID['kondisiCahaya']) {
          kondisiCahaya
              .add({'value': e['id'], 'title': e['name'], 'isChecked': false});
        } else if (e['grp_id'] == grpID['cuaca']) {
          cuaca.add({'value': e['id'], 'title': e['name'], 'isChecked': false});
        } else if (e['grp_id'] == grpID['informasiKhusus']) {
          informasiKhusus
              .add({'value': e['id'], 'title': e['name'], 'isChecked': false});
        } else if (e['grp_id'] == grpID['tipeKecalakaan']) {
          tipeKecalakaan
              .add({'value': e['id'], 'title': e['name'], 'isChecked': false});
        } else if (e['grp_id'] == grpID['kecelakaanMenonjol']) {
          kecelakaanMenonjol
              .add({'value': e['id'], 'title': e['name'], 'isChecked': false});
        } else if (e['grp_id'] == grpID['kerusakanMaterial']) {
          kerusakanMaterial
              .add({'value': e['id'], 'title': e['name'], 'isChecked': false});
        }
      }
    }
  }

  String _tipeKecelakaan = 'A0700';
  String _tipeKecelakaanGambar = "assets/accident_diagrams/A0700.svg";
  String _cuaca = 'A0900';
  String _cahaya = 'A0800';

  // final TextEditingController _nilaiRugiKendaraanController =
  //     TextEditingController();
  final TextEditingController _nilaiRugiNonKendaraanController =
      TextEditingController();

  final TextEditingController _tkpLakaController = TextEditingController();

  final TextEditingController _searchController = TextEditingController();

  final RealtimeLocation _realtimeLocation = RealtimeLocation();
  Userlocation _userlocation =
      Userlocation(latitude: -6.2440791, longitude: 106.854604);

  Future<void> _initUserlocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    locationData = await location.getLocation();

    if (mounted) {
      setState(() {
        _userlocation = Userlocation(
            latitude: locationData.latitude ?? -6.2440791,
            longitude: locationData.longitude ?? 106.854604);
      });
    }
  }

  // Future<void> checkInternetConnection() async {
  //   var connectivityResult = await Connectivity().checkConnectivity();
  //   if (connectivityResult == ConnectivityResult.mobile ||
  //       connectivityResult == ConnectivityResult.wifi) {
  //     setState(() {
  //       _isConnected = true;
  //       print('Ada koneksi');
  //     });
  //   } else {
  //     setState(() {
  //       _isConnected = false;
  //       print('tidak Ada koneksi');
  //     });
  //   }
  // }

  void _showImageDialog(BuildContext context, String? imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: imageUrl != null
              ? Image.file(
                  File(imageUrl),
                  fit: BoxFit.cover,
                )
              : Container(
                  color: Colors.grey,
                  child: const Icon(
                    Icons.image,
                    size: 150,
                    color: Colors.white,
                  ),
                ),
        );
      },
    );
  }

  @override
  void initState() {
    // checkInternetConnection();
    _dbhelper = Dbhelper();
    _dbhelper.initializeDB().whenComplete(() async {
      _pictures = await _dbhelper.queryRows(
          table: 'pictures', where: "accidentUuid = '${widget.accidentUuid}'");

      if (_pictures.isNotEmpty) {
        List json = jsonDecode(_pictures[0]['path']);
        for (var i = 0; i < json.length; i++) {
          _files[i] = File(json[i]);
          _images.add(json[i]);
        }

        setState(() {});
      }
      _listLaka = await _dbhelper.queryAllRows('laka');
      _listRef = await _dbhelper.queryAllRows('ref');
      // _saksi = await _dbhelper.queryRows(
      //     table: 'saksi', where: "accidentUuid = '${widget.accidentUuid}'");

      setState(() {
        loading = false;
      });
    });

    Future.delayed(Duration.zero, () async {
      await _initUserlocation();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token') ?? '';

      await _fetchReferences();

      var controller = 'petugas/profile';
      var params = {'token': _token};
      Map<String, dynamic> profile =
          await RestClient().get(controller: controller, params: params);

      if (profile['status']) {
        if (widget.accidentData != null) {
          setState(() {
            _petugasPelapor['nama'] = widget.accidentData!['petugas'];
            _petugasPelapor['nrp'] = widget.accidentData!['nrp'];
            _petugasPelapor['polda'] = widget.accidentData!['polda'];
            _petugasPelapor['polres'] = widget.accidentData!['polres'];

            _tanggalKejadian = widget.accidentData!['tanggalKejadian'];
            _tanggalLaporan = widget.accidentData!['tanggalLaporan'];
            _jamKejadian = widget.accidentData!['jamKejadian'];
            _jamLaporan = widget.accidentData!['jamLaporan'];

            informasiKhusus.asMap().entries.forEach((e) {
              informasiKhusus[e.key]['isChecked'] =
                  (widget.accidentData!['informasiKhusus'])
                          .indexOf(e.value['value']) >
                      -1;
            });

            kecelakaanMenonjol.asMap().entries.forEach((e) {
              kecelakaanMenonjol[e.key]['isChecked'] =
                  (widget.accidentData!['kecelakaanMenonjol'])
                          .indexOf(e.value['value']) >
                      -1;
            });

            kerusakanMaterial.asMap().entries.forEach((e) {
              kerusakanMaterial[e.key]['isChecked'] =
                  (widget.accidentData!['kerusakanMaterial'])
                          .indexOf(e.value['value']) >
                      -1;
            });

            //  _tipeKecelakaan = widget.accidentData!['tipeKecelakaan'];
            _cahaya = widget.accidentData!['kondisiCahaya'];
            _cuaca = widget.accidentData!['cuaca'];

            _nilaiRugiNonKendaraanController.text =
                widget.accidentData!['nilaiRugiNonKendaraan'].toString();
            loading = false;
          });
        } else {
          //
          _tanggalKejadian = intl.DateFormat('yyyy-MM-dd').format(_timestamp);
          _tanggalLaporan = intl.DateFormat('yyyy-MM-dd').format(_timestamp);
          _jamKejadian = intl.DateFormat.Hms().format(_timestamp);
          _jamLaporan = intl.DateFormat.Hms().format(_timestamp);

          String nama = profile['rows'][0]['first_name'];
          if (profile['rows'][0]['last_name'] != null) {
            nama += ' ';
            nama += profile['rows'][0]['last_name'];
          }

          _petugasPelapor['nama'] = nama;
          _petugasPelapor['nrp'] = profile['rows'][0]['officer_id'];

          var polda = await RestClient().get(
              controller: 'polda',
              params: {'token': _token, 'id': profile['rows'][0]['polda_id']});
          if (polda['total'] == 1) {
            _petugasPelapor['polda'] = polda['rows'][0]['name'];
          }

          var polres = await RestClient().get(
              controller: 'polres',
              params: {'token': _token, 'id': profile['rows'][0]['polres_id']});
          if (polres['total'] == 1) {
            _petugasPelapor['polres'] = polres['rows'][0]['name'];
          }
        }
        setState(() {});
      } else if (mounted) {
        setState(() {
          _petugasPelapor['nama'] = '${_listLaka[0]['name']}';
          _petugasPelapor['nrp'] = '${_listLaka[0]['nrp']}';
          _petugasPelapor['polda'] = '${_listLaka[0]['polda']}';
          _petugasPelapor['polres'] = '${_listLaka[0]['polres']}';

          _tanggalKejadian = widget.accidentData!['tanggalKejadian'];
          _tanggalLaporan = widget.accidentData!['tanggalLaporan'];
          _jamKejadian = widget.accidentData!['jamKejadian'];
          _jamLaporan = widget.accidentData!['jamLaporan'];

          informasiKhusus.asMap().entries.forEach((e) {
            informasiKhusus[e.key]['isChecked'] =
                (widget.accidentData!['informasiKhusus'])
                        .indexOf(e.value['value']) >
                    -1;
          });

          kecelakaanMenonjol.asMap().entries.forEach((e) {
            kecelakaanMenonjol[e.key]['isChecked'] =
                (widget.accidentData!['kecelakaanMenonjol'])
                        .indexOf(e.value['value']) >
                    -1;
          });

          kerusakanMaterial.asMap().entries.forEach((e) {
            kerusakanMaterial[e.key]['isChecked'] =
                (widget.accidentData!['kerusakanMaterial'])
                        .indexOf(e.value['value']) >
                    -1;
          });

          //  _tipeKecelakaan = widget.accidentData!['tipeKecelakaan'];
          _cahaya = widget.accidentData!['kondisiCahaya'];
          _cuaca = widget.accidentData!['cuaca'];

          _nilaiRugiNonKendaraanController.text =
              widget.accidentData!['nilaiRugiNonKendaraan'].toString();
        });
        // showDialog(
        //     context: context,
        //     builder: (context) => AlertDialog(
        //           title: const Text('IRSMS'),
        //           content: Text(profile['error']),
        //           actions: [
        //             ElevatedButton(
        //                 onPressed: () {
        //                   if (profile['error'] == 'Expired token') {
        //                     Navigator.pushNamed(context, '/');
        //                   } else {
        //                     Navigator.of(context).pop();
        //                   }
        //                 },
        //                 child: const Text('Tutup'))
        //           ],
        //         ));
      }
    });

    _realtimeLocation.locationStream.listen((userLocation) {
      if (!mounted) return;
      setState(() {
        _userlocation = userLocation;
      });
    });

    super.initState();
    _tanggalKejadian = intl.DateFormat('yyyy-MM-dd').format(DateTime.now());
    _tanggalLaporan = intl.DateFormat('yyyy-MM-dd').format(DateTime.now());
    _jamKejadian = intl.DateFormat('hh:mm:ss').format(DateTime.now());
    _jamLaporan = intl.DateFormat('hh:mm:ss').format(DateTime.now());
  }

  @override
  void dispose() {
    _nilaiRugiNonKendaraanController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //  final size = MediaQuery.of(context).size;
    List<String> imagePaths = [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Tambah Data'),
      ),
      body: loading // Tampilkan loading indicator jika sedang memuat
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.asset(
                                    'assets/images/Insignia_of_the_Indonesian_Traffic_Police.svg.png',
                                    width: 96,
                                    height: 96,
                                  )),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Petugas Pelapor",
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        _petugasPelapor['nama'].toString(),
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                            color:
                                                Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.w900),
                                      )
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                          Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 32,
                                  child: Text(
                                    'Foto Lokasi Laka',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                        height: 3),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  for (int index = 0;
                                      index < widget.imageUrls.length;
                                      index++)
                                    InkWell(
                                      onTap: () {
                                        _showImageDialog(
                                            context, widget.imageUrls[index]);
                                      },
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text("Lokasi ${index + 1}"),
                                          // const SizedBox(height: 2),
                                          widget.imageUrls[index] != null
                                              ? Card(
                                                  elevation: 2,
                                                  child: SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            3.5,
                                                    height: 150,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              4.0),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        child: Image.file(
                                                          File(widget.imageUrls[
                                                              index]!),
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : Container(
                                                  width: 400,
                                                  height: 300,
                                                  color: Colors.grey,
                                                  child: const Icon(Icons.image,
                                                      size: 50,
                                                      color: Colors.white),
                                                ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              Card(
                                elevation: 2,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          children: [
                                            Text(
                                              'NRP',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text('${_petugasPelapor['nrp']}',
                                                style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontWeight:
                                                        FontWeight.w900))
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              'POLDA',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                                _petugasPelapor['polda']
                                                    .toString(),
                                                style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontWeight:
                                                        FontWeight.w900))
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              'POLRES',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                                _petugasPelapor['polres']
                                                    .toString(),
                                                style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontWeight:
                                                        FontWeight.w900))
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 16,
                              ),

                              // Row(
                              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              //   children: [
                              //     ..._files.asMap().entries.map((e) {
                              //       double width =
                              //           ((MediaQuery.of(context).size.width - 72) /
                              //               5);
                              //       double height = width;

                              //       return CardPicture(
                              //         onTap: () async {
                              //           showModalBottomSheet(
                              //               shape: const RoundedRectangleBorder(
                              //                   borderRadius: BorderRadius.vertical(
                              //                       top: Radius.circular(8.0))),
                              //               context: context,
                              //               isScrollControlled: true,
                              //               builder: (context) => Padding(
                              //                     padding: MediaQuery.of(context)
                              //                         .viewInsets,
                              //                     child: Padding(
                              //                       padding:
                              //                           const EdgeInsets.all(20.0),
                              //                       child: Column(
                              //                         mainAxisSize: MainAxisSize.min,
                              //                         crossAxisAlignment:
                              //                             CrossAxisAlignment.stretch,
                              //                         children: [
                              //                           ElevatedButton(
                              //                               onPressed: () async {
                              //                                 Navigator.of(context)
                              //                                     .pop();
                              //                                 XFile? xFile =
                              //                                     await _picker.pickImage(
                              //                                         source:
                              //                                             ImageSource
                              //                                                 .camera,
                              //                                         maxWidth: 500,
                              //                                         maxHeight: 500);

                              //                                 if (xFile != null) {
                              //                                   setState(() {
                              //                                     _files[e.key] =
                              //                                         File(
                              //                                             xFile.path);
                              //                                     if (_images.length >
                              //                                         e.key) {
                              //                                       _images[e.key] =
                              //                                           xFile.path;
                              //                                     } else {
                              //                                       _images.add(
                              //                                           xFile.path);
                              //                                     }
                              //                                   });
                              //                                 }
                              //                               },
                              //                               child:
                              //                                   const Text('Kamera')),
                              //                           ElevatedButton(
                              //                               onPressed: () async {
                              //                                 Navigator.of(context)
                              //                                     .pop();

                              //                                 XFile? xFile =
                              //                                     await _picker.pickImage(
                              //                                         source:
                              //                                             ImageSource
                              //                                                 .gallery,
                              //                                         maxWidth: 500,
                              //                                         maxHeight: 500);

                              //                                 if (xFile != null) {
                              //                                   setState(() {
                              //                                     _files[e.key] =
                              //                                         File(
                              //                                             xFile.path);
                              //                                     if (_images.length >
                              //                                         e.key) {
                              //                                       _images[e.key] =
                              //                                           xFile.path;
                              //                                     } else {
                              //                                       _images.add(
                              //                                           xFile.path);
                              //                                     }
                              //                                   });
                              //                                 }
                              //                               },
                              //                               child:
                              //                                   const Text('Galeri')),
                              //                         ],
                              //                       ),
                              //                     ),
                              //                   ));
                              //         },
                              //         imagePath: _files[e.key]?.path,
                              //         // width: width,
                              //         // height: height,
                              //       );
                              //     })
                              //   ],
                              // ),

                              const SizedBox(
                                height: 16,
                              ),

                              Card(
                                elevation: 2,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Text(
                                                'Tanggal Kejadian',
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const SizedBox(
                                                height: 8,
                                              ),
                                              InkWell(
                                                onTap: () async {
                                                  var newDate =
                                                      await showDatePicker(
                                                    context: context,
                                                    initialDate: DateTime.parse(
                                                        _tanggalKejadian),
                                                    firstDate: DateTime(1900),
                                                    lastDate: DateTime.now(),
                                                  );

                                                  // Don't change the date if the date picker returns null.
                                                  if (newDate == null) {
                                                    return;
                                                  }
                                                  setState(() {
                                                    _tanggalKejadian =
                                                        intl.DateFormat(
                                                                'yyyy-MM-dd')
                                                            .format(newDate);
                                                  });
                                                },
                                                child: Text(_tanggalKejadian,
                                                    style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontWeight:
                                                            FontWeight.w900)),
                                              )
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Text(
                                                'Tanggal Laporan',
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const SizedBox(
                                                height: 8,
                                              ),
                                              InkWell(
                                                onTap: () async {
                                                  var newDate =
                                                      await showDatePicker(
                                                    context: context,
                                                    initialDate: DateTime.parse(
                                                        _tanggalLaporan),
                                                    firstDate: DateTime.parse(
                                                        _tanggalKejadian),
                                                    lastDate: DateTime.now(),
                                                  );

                                                  // Don't change the date if the date picker returns null.
                                                  if (newDate == null) {
                                                    return;
                                                  }
                                                  setState(() {
                                                    _tanggalLaporan =
                                                        intl.DateFormat(
                                                                'yyyy-MM-dd')
                                                            .format(newDate);
                                                  });
                                                },
                                                child: Text(_tanggalLaporan,
                                                    style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontWeight:
                                                            FontWeight.w900)),
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 16,
                              ),

                              Card(
                                elevation: 2,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Text(
                                                'Jam Kejadian',
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const SizedBox(
                                                height: 8,
                                              ),
                                              InkWell(
                                                onTap: () async {
                                                  var newTime =
                                                      await showTimePicker(
                                                          context: context,
                                                          initialTime:
                                                              TimeOfDay.now());

                                                  // Don't change the date if the date picker returns null.
                                                  if (newTime == null) {
                                                    return;
                                                  }

                                                  setState(() {
                                                    String H = newTime.hour
                                                        .toString()
                                                        .padLeft(2, '0');
                                                    String M = newTime.minute
                                                        .toString()
                                                        .padLeft(2, '0');

                                                    _jamKejadian = '$H:$M';
                                                  });
                                                },
                                                child: Text(_jamKejadian,
                                                    style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontWeight:
                                                            FontWeight.w900)),
                                              )
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Text(
                                                'Jam Laporan',
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const SizedBox(
                                                height: 8,
                                              ),
                                              InkWell(
                                                onTap: () async {
                                                  var newTime =
                                                      await showTimePicker(
                                                          context: context,
                                                          initialTime:
                                                              TimeOfDay.now());

                                                  // Don't change the date if the date picker returns null.
                                                  if (newTime == null) {
                                                    return;
                                                  }

                                                  setState(() {
                                                    String H = newTime.hour
                                                        .toString()
                                                        .padLeft(2, '0');
                                                    String M = newTime.minute
                                                        .toString()
                                                        .padLeft(2, '0');

                                                    _jamLaporan = '$H:$M';
                                                  });
                                                },
                                                child: Text(_jamLaporan,
                                                    style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontWeight:
                                                            FontWeight.w900)),
                                              )
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 16,
                              ),

                              Card(
                                elevation: 2,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Text(
                                                'Latitude',
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const SizedBox(
                                                height: 8,
                                              ),
                                              Text(
                                                  widget.accidentData != null
                                                      ? '${widget.accidentData!['latitude']}'
                                                      : '${_userlocation.latitude}',
                                                  style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontWeight:
                                                          FontWeight.w900))
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Text(
                                                'Longitude',
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const SizedBox(
                                                height: 8,
                                              ),
                                              Text(
                                                  widget.accidentData != null
                                                      ? '${widget.accidentData!['latitude']}'
                                                      : '${_userlocation.longitude}',
                                                  style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontWeight:
                                                          FontWeight.w900))
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 16,
                              ),

                              // Card(
                              //   elevation: 2,
                              //   child: SizedBox(
                              //     width: double.infinity,
                              //     child: Column(
                              //       children: [
                              //         Text(
                              //           'Informasi Khusus',
                              //           style: TextStyle(
                              //               color: Theme.of(context).primaryColor,
                              //               height: 3,
                              //               fontWeight: FontWeight.bold),
                              //         ),
                              //         Column(
                              //           children: informasiKhusus
                              //               .map((e) => CheckboxListTile(
                              //                   value: e['isChecked'],
                              //                   title: Text(e['title']),
                              //                   onChanged: (newValue) {
                              //                     setState(() {
                              //                       e['isChecked'] = newValue;
                              //                     });
                              //                   }))
                              //               .toList(),
                              //         )
                              //       ],
                              //     ),
                              //   ),
                              // ),
                              // const SizedBox(
                              //   height: 16,
                              // ),
                              // Card(
                              //   elevation: 2,
                              //   child: SizedBox(
                              //     width: double.infinity,
                              //     child: Column(
                              //       children: [
                              //         Text(
                              //           'Kecelakaan Menonjol',
                              //           style: TextStyle(
                              //               color: Theme.of(context).primaryColor,
                              //               height: 3,
                              //               fontWeight: FontWeight.bold),
                              //         ),
                              //         Column(
                              //           children: kecelakaanMenonjol
                              //               .map((e) => CheckboxListTile(
                              //                   value: e['isChecked'],
                              //                   title: Text(e['title']),
                              //                   onChanged: (newValue) {
                              //                     setState(() {
                              //                       e['isChecked'] = newValue;
                              //                     });
                              //                   }))
                              //               .toList(),
                              //         ),
                              //       ],
                              //     ),
                              //   ),
                              // ),

                              Card(
                                elevation: 2,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    children: [
                                      // Text(
                                      //   'Kerusakaan Material / Infrastruktur',
                                      //   style: TextStyle(
                                      //       color: Theme.of(context).primaryColor,
                                      //       fontWeight: FontWeight.bold,
                                      //       height: 3),
                                      // ),
                                      // Column(
                                      //   children: kerusakanMaterial
                                      //       .map((e) => CheckboxListTile(
                                      //           value: e['isChecked'],
                                      //           title: Text(e['title']),
                                      //           onChanged: (newValue) {
                                      //             setState(() {
                                      //               e['isChecked'] = newValue;
                                      //             });
                                      //           }))
                                      //       .toList(),
                                      // ),

                                      Padding(
                                        padding: const EdgeInsets.only(
                                            right: 16.0,
                                            bottom: 16.0,
                                            left: 10.0,
                                            top: 10.0),
                                        child: Column(
                                          children: [
                                            TextFormField(
                                              controller: _tkpLakaController,
                                              //  keyboardType: TextInputType.,
                                              onChanged: (value) {},
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                                filled:
                                                    true, // Mengaktifkan latar belakang yang diisi
                                                fillColor: Colors.white,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 0.0,
                                                        horizontal: 5.0),
                                                icon: Column(
                                                  children: [
                                                    Text(
                                                      'TKP',
                                                      style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .primaryColor,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Text(
                                                      'Laka',
                                                      style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .primaryColor,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              autovalidateMode:
                                                  AutovalidateMode.always,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return '* wajib diisi';
                                                }

                                                return null;
                                              },
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),

                              const Text(
                                'Tipe Kecelakaan',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    height: 3),
                              ),

                              Card(
                                elevation: 2,
                                child: SizedBox(
                                    width: double.infinity,
                                    height: 96,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(children: [
                                        SizedBox(
                                          width: 64,
                                          height: 64,
                                          child: SvgPicture.asset(
                                            _tipeKecelakaanGambar,
                                            placeholderBuilder: (context) =>
                                                const CircularProgressIndicator(),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 8,
                                        ),
                                       
                                      ]),
                                    )),
                              ),
                              const Text(
                                'Kondisi Cahaya',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    height: 3),
                              ),
                              Card(
                                elevation: 2,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    children: [
                                      ...kondisiCahaya.map(
                                        (e) {
                                          return RadioListTile(
                                            title: Text(e['title'].toString()),
                                            value: e['value'].toString(),
                                            groupValue: _cahaya,
                                            onChanged: (value) {
                                              setState(() {
                                                _cahaya = value.toString();
                                              });
                                            },
                                            controlAffinity:
                                                ListTileControlAffinity
                                                    .trailing,
                                          );
                                        },
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              // ------------------------------------

                              const Text(
                                'Cuaca',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    height: 3),
                              ),
                              Card(
                                elevation: 2,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    children: [
                                      ...cuaca.map(
                                        (e) {
                                          return RadioListTile(
                                            title: Text(e['title'].toString()),
                                            value: e['value'].toString(),
                                            groupValue: _cuaca,
                                            onChanged: (value) {
                                              setState(() {
                                                _cuaca = value.toString();
                                              });
                                            },
                                            controlAffinity:
                                                ListTileControlAffinity
                                                    .trailing,
                                          );
                                        },
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              // ------------------------------------

                              // const Text(
                              //   'Data Kerusakan & Data Kerugian Material',
                              //   style: TextStyle(
                              //       color: Colors.grey,
                              //       fontWeight: FontWeight.bold,
                              //       height: 3),
                              // ),

                              Card(
                                elevation: 2,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    children: [
                                      // Text(
                                      //   'Kerusakaan Material / Infrastruktur',
                                      //   style: TextStyle(
                                      //       color: Theme.of(context).primaryColor,
                                      //       fontWeight: FontWeight.bold,
                                      //       height: 3),
                                      // ),
                                      // Column(
                                      //   children: kerusakanMaterial
                                      //       .map((e) => CheckboxListTile(
                                      //           value: e['isChecked'],
                                      //           title: Text(e['title']),
                                      //           onChanged: (newValue) {
                                      //             setState(() {
                                      //               e['isChecked'] = newValue;
                                      //             });
                                      //           }))
                                      //       .toList(),
                                      // ),

                                      Padding(
                                        padding: const EdgeInsets.only(
                                            right: 16.0,
                                            bottom: 16.0,
                                            left: 16.0),
                                        child: Column(
                                          children: [
                                            Text(
                                              'Perkiraan Nilai Rugi Material Non Kendaraan',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                  height: 3),
                                            ),
                                            TextFormField(
                                              controller:
                                                  _nilaiRugiNonKendaraanController,
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (value) {},
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 0.0,
                                                        horizontal: 8.0),
                                                icon: const Text(
                                                  'Rp',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.grey),
                                                ),
                                              ),
                                              autovalidateMode:
                                                  AutovalidateMode.always,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return '* wajib diisi';
                                                }

                                                return null;
                                              },
                                              inputFormatters: [
                                                CurrencyInputFormatter()
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 15,
                              ),

                              IntrinsicHeight(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Expanded(
                                    //   child: ElevatedButton(
                                    //       onPressed: () {
                                    //         bool tidakAdaSaksi = false;

                                    //         for (var element in informasiKhusus) {
                                    //           if (element['value'] == 'A0602') {
                                    //             tidakAdaSaksi = element['isChecked'];
                                    //           }
                                    //         }

                                    //         if (tidakAdaSaksi == false) {
                                    //           Navigator.push(
                                    //               context,
                                    //               MaterialPageRoute(
                                    //                   builder: (context) => FormSaksi(
                                    //                         accidentUuid:
                                    //                             widget.accidentUuid,
                                    //                       )));
                                    //         }
                                    //       },
                                    //       style: ButtonStyle(
                                    //         backgroundColor: MaterialStateProperty.all(
                                    //             Theme.of(context).primaryColor),
                                    //         padding: MaterialStateProperty.all(
                                    //             const EdgeInsets.all(16)),
                                    //       ),
                                    //       child: Row(
                                    //         mainAxisAlignment: MainAxisAlignment.center,
                                    //         children: [
                                    //           const Icon(
                                    //             Icons.add_circle,
                                    //             color: Color(0xfff8c301),
                                    //           ),
                                    //           const SizedBox(width: 16.0),
                                    //           Text(
                                    //             'Saksi (${_saksi.length})',
                                    //             style:
                                    //                 const TextStyle(color: Colors.white),
                                    //           )
                                    //         ],
                                    //       )),
                                    // ),
                                    // const SizedBox(
                                    //   width: 16.0,
                                    // ),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          if (_formKey.currentState!
                                                  .validate() &&
                                              !isLoading) {
                                            await _submit();
                                          }
                                        },
                                        style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStateProperty.all(
                                                  Theme.of(context)
                                                      .primaryColor),
                                          shape: MaterialStateProperty.all<
                                              RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                          ),
                                          padding: MaterialStateProperty.all(
                                              const EdgeInsets.all(16)),
                                        ),
                                        child: (isLoading)
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 1.5,
                                                ),
                                              )
                                            : const Text(
                                                'Kirim',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
    );
  }

  Future<void> _submit() async {
    final List<String> imageUrls;
    // String getData(List source) {
    //   List buffer = [];

    //   for (var element in source) {
    //     if (element['isChecked']) {
    //       buffer.add(element['value']);
    //     }
    //   }

    //   return jsonEncode(buffer);
    // }

    setState(() {
      isLoading = true;
    });

    //  var reso = await RestClient().uploadPhotos([imagePath]);
    // String fileName = reso['rows'][0]['file_name'];

    //   String fileName = path.basename(widget.imageFile!.path);
    // final Map<String, dynamic> accidentRecord = {
    //   'accidentUuid': widget.accidentUuid,
    //   'latitude': widget.accidentData != null
    //       ? widget.accidentData!['latitude']
    //       : _userlocation.latitude,
    //   'longitude': widget.accidentData != null
    //       ? widget.accidentData!['longitude']
    //       : _userlocation.longitude,
    //   'petugas': _petugasPelapor['nama'],
    //   'nrp': _petugasPelapor['nrp'],
    //   'polda': _petugasPelapor['polda'],
    //   'polres': _petugasPelapor['polres'],
    //   'tanggalKejadian': _tanggalKejadian,
    //   'jamKejadian': _jamKejadian,
    //   'tanggalLaporan': _tanggalLaporan,
    //   'jamLaporan': _jamLaporan,
    //   'informasiKhusus': '[]',
    //   'kecelakaanMenonjol': '[]',
    //   'tipeKecelakaan': _tipeKecelakaan,
    //   'kondisiCahaya': _cahaya,
    //   'cuaca': _cuaca,
    //   'kerusakanMaterial': '[]',
    //   'nilaiRugiNonKendaraan':
    //       _nilaiRugiNonKendaraanController.text.replaceAll('.', ''),
    //   'nilaiRugiKendaraan': '0',
    //   'tkpLaka': _tkpLakaController.text,
    // };
    final Map<String, dynamic> accidentRecord = {
      'accidentUuid': widget.accidentUuid,
      'latitude': widget.accidentData != null
          ? widget.accidentData!['latitude']
          : _userlocation.latitude,
      'longitude': widget.accidentData != null
          ? widget.accidentData!['longitude']
          : _userlocation.longitude,
      'petugas': _petugasPelapor['nama'],
      'nrp': _petugasPelapor['nrp'],
      'polda': _petugasPelapor['polda'],
      'polres': _petugasPelapor['polres'],
      'tanggalKejadian': _tanggalKejadian,
      'jamKejadian': _jamKejadian,
      'tanggalLaporan': _tanggalLaporan,
      'jamLaporan': _jamLaporan,
      'informasiKhusus': '[]',
      'kecelakaanMenonjol': '[]',
      'tipeKecelakaan': _tipeKecelakaan,
      'kondisiCahaya': _cahaya,
      'cuaca': _cuaca,
      'kerusakanMaterial': '[]',
      'nilaiRugiNonKendaraan':
          _nilaiRugiNonKendaraanController.text.replaceAll('.', ''),
      'nilaiRugiKendaraan': '0',
      'tkpLaka': _tkpLakaController.text,
    };
    print(accidentRecord);

    try {
      var result = 0;
      if (widget.accidentData == null) {
        result = await _dbhelper.insert(
          table: 'accident',
          data: accidentRecord,
        );

        for (int i = 0; i < widget.imageUrls.length; i++) {
          String imagePath = widget.imageUrls[i]!;
          _imagePaths.add(imagePath);

          // Ambil nama file menggunakan path.basename
          String fileName = path.basename(imagePath);
          print(fileName);

          // Buat data untuk dimasukkan ke database
          var data = {'accidentUuid': widget.accidentUuid, 'path': fileName};

          // Masukkan data ke dalam database
          result = await _dbhelper.insert(
            table: 'pictures',
            data: data,
          );
          //  }
        }
        if (_imagePaths.isNotEmpty) {
          print('Data sudah terisi di _imagePaths');
        } else {
          print('Data masih kosong di _imagePaths');
        }
      } else {
        result = await _dbhelper.update(
            table: 'accident',
            data: accidentRecord,
            columnPK: 'accidentUuid',
            whereArgs: [widget.accidentUuid]);
      }

      setState(() {
        isLoading = false;
      });

      if (mounted && result == 0) {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('IRSMS'),
                  content: const Text('Gagal menyimpan perubahan data.'),
                  actions: [
                    ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Tutup'))
                  ],
                ));
      } else {
        if (_images.isNotEmpty) {
          var data = {
            'accidentUuid': widget.accidentUuid,
            'path': jsonEncode(_images)
          };

          if (_pictures.isEmpty) {
            await _dbhelper.insert(table: 'pictures', data: data);
          } else {
            var pictureId = _pictures[0]['pictureId'];
            await _dbhelper.update(
                table: 'pictures',
                data: data,
                columnPK: 'pictureId',
                whereArgs: [pictureId]);
          }
        }

        await Future.delayed(const Duration(seconds: 0));
        if (!mounted) return;

        Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DaftarLaka(imageUrls: _imagePaths)))
            .then((value) => setState(() {}));

        // Navigator.pushAndRemoveUntil(
        //         context,
        //         MaterialPageRoute(
        //             builder: (context) => DaftarLaka(imageUrls: _imagePaths)),
        //         ModalRoute.withName(
        //             '/desktop') // Ini akan menghapus semua rute sebelumnya
        //         )
        //     .then((value) => setState(() {}));
      }
    } catch (e) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('IRSMS'),
                content: Text(e.toString()),
                actions: [
                  ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Tutup'))
                ],
              ));
    }

    setState(() {
      isLoading = false;
    });
  }

  // @override
  // void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  //   super.debugFillProperties(properties);
  //   properties.add(DiagnosticsProperty<File?>('_image', _image));
  // }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    // Remove commas and dots from the entered value
    String newText = newValue.text.replaceAll(',', '').replaceAll('.', '');

    // Parse the text into a double value
    double value = double.tryParse(newText) ?? 0.0;

    // Reformat the value with comma as thousand separator
    final formatter = NumberFormat("#,##0", "id_ID");

    // Convert the value into a formatted currency string
    newText = formatter.format(value);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class CheckboxWidget extends StatelessWidget {
  const CheckboxWidget(
      {required this.title,
      this.initialValue = false,
      this.onChanged,
      this.validator,
      super.key});

  final String title;
  final bool initialValue;
  final void Function(bool? val)? onChanged;
  final Function(bool? val)? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<bool>(
      initialValue: initialValue,
      builder: (FormFieldState<bool> state) {
        return Column(
          children: [
            Row(
              children: [
                Checkbox(
                    value: state.value,
                    onChanged: (value) {
                      onChanged!(value);
                      state.didChange(value);
                    }),
                Text(title),
              ],
            ),
            if (state.errorText != null && state.errorText != "")
              Text(
                state.errorText.toString(),
                style: const TextStyle(color: Colors.red),
              )
          ],
        );
      },
      validator: (value) {
        return validator!(value);
      },
    );
  }
}
