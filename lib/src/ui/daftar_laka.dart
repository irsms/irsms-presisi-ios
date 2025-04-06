// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_irsms/src/helpers/dbhelper.dart';
import 'package:flutter_application_irsms/src/ui/camera.dart';
// import 'package:flutter_application_irsms_petugas/src/ui/card_picture.dart';;
import 'package:flutter_pagination/flutter_pagination.dart';
import 'package:flutter_pagination/widgets/button_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import '../services/rest_client.dart';

class DaftarLaka extends StatefulWidget {
  // final List<String> imageUrls;
  // Tambahkan parameter untuk menerima imageUrls
  final List<String?> imageUrls;
  const DaftarLaka({
    Key? key,
    required this.imageUrls,
  }) : super(key: key);

  @override
  State<DaftarLaka> createState() => _DaftarLakaState();
}

class _DaftarLakaState extends State<DaftarLaka> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late Dbhelper _dbhelper;
  List _listAccident = [];
  List _listLaka = [];
  File? modifiedImage;

  // List<String> get _imagePaths => [modifiedImage!.path];

  CameraDescription? camera;
  CameraController? controller;

  int currentPage = 1;

  String _token = '';

  int _totalPage = 0;

  int _currentPage = 1;

  // final String _accidentUuid = const Uuid().v1();

  bool _isLoading = false;

  final Color _buttonBackgroundColor = const Color(0xfff8c301);

  @override
  void initState() {
    _dbhelper = Dbhelper();

    _dbhelper.initializeDB().whenComplete(() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token') ?? '';

      await _getLaporan();

      setState(() {});
    });

    super.initState();

    // getCurrentLocation();
  }

  // Future<void> getCurrentLocation() async {
  //   Location location = Location();
  //   try {
  //     var currentLocation = await location.getLocation();
  //     print(
  //         'Latitude: ${currentLocation.latitude}, Longitude: ${currentLocation.longitude}');
  //   } catch (e) {
  //     print('Error: $e');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/desktop');
        return false; // Mencegah navigasi back default
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Daftar Laka'),
          leading: IconButton(
              onPressed: (() => Navigator.pushNamed(context, '/desktop')),
              icon: const Icon(Icons.arrow_back)),
          bottom: PreferredSize(
            preferredSize: const Size(double.infinity, 80),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  // height: 20,
                  child: ElevatedButton(
                    onPressed: () async {
                      _getCamera();
                    },
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(_buttonBackgroundColor),
                        padding:
                            MaterialStateProperty.all(const EdgeInsets.all(16)),
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0)))),
                    child: Text(
                      'Tambah Data',
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold),
                    ),
                  )),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await _getLaporan(page: _currentPage);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(4)),
                          child: IntrinsicHeight(
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    width: kToolbarHeight,
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4)),
                                    child: Center(
                                      child: Text(
                                        _totalPage.toString(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  const Center(
                                    child: Text(
                                      'Belum Sinkronisasi',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  )
                                ]),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      SizedBox(
                        width: 70,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!_isLoading) {
                              await _sinkronisasi();
                            }
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                                _buttonBackgroundColor),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                          child: (_isLoading)
                              ? const SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    //  strokeWidth: 1.5,
                                  ),
                                )
                              : const Icon(
                                  Icons.sync,
                                  size: 20,
                                ),
                        ),
                      )
                    ],
                  ),
                ),
                const Center(
                  child: Text(
                    'Daftar Laka',
                    style: TextStyle(
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        height: 2),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ..._listAccident.map((e) {
                      return LakaTile(
                        accidentModel: e,
                        onDelete: () async {
                          _totalPage =
                              await _dbhelper.queryRowCount('accident');
                          _listAccident =
                              await _dbhelper.queryAllRows('accident');

                          setState(() {});
                        },
                      );
                    })
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: (_totalPage > 5
                      ? Pagination(
                          paginateButtonStyles: PaginateButtonStyles(
                              activeBackgroundColor:
                                  Theme.of(context).primaryColor,
                              backgroundColor: Colors.white,
                              paginateButtonBorderRadius:
                                  BorderRadius.circular(50),
                              textStyle: TextStyle(
                                color: Theme.of(context).primaryColor,
                              )),
                          prevButtonStyles: PaginateSkipButton(
                            icon: Icon(
                              Icons.chevron_left,
                              color: Theme.of(context).primaryColor,
                            ),
                            borderRadius: BorderRadius.circular(50),
                            buttonBackgroundColor: Colors.white,
                          ),
                          nextButtonStyles: PaginateSkipButton(
                              icon: Icon(
                                Icons.chevron_right,
                                color: Theme.of(context).primaryColor,
                              ),
                              borderRadius: BorderRadius.circular(50),
                              buttonBackgroundColor: Colors.white),
                          onPageChange: (page) {
                            setState(() {
                              _currentPage = page;
                            });
                          },
                          useGroup: false,
                          totalPage: _totalPage,
                          show: _totalPage - 1,
                          currentPage: _currentPage,
                        )
                      : const SizedBox(
                          width: double.infinity,
                        )),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _opCamera() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Minta izin jika belum diberikan
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Izin ditolak, tampilkan pesan atau arahkan pengguna untuk mengaktifkan izin
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location permission denied'),
        ));
        return;
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OpenCamera()),
    );
  }

  Future<void> _getCamera() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Foto TKP Laka"),
          content: const Text(
              "Sebelum membuat laporan laka. foto terlebih dahulu tkp Laka "),
          actions: <Widget>[
            TextButton(
              child: const Text("BATAL"),
              onPressed: () {
                Navigator.of(context).pop();
                // _formTambahData(_accidentUuid, _imagess);
              },
            ),
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                //   _formTambahData(_accidentUuid, _imagess);
                _opCamera();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _getLaporan({int? page}) async {
    var profile =
        await RestClient().get(controller: 'petugas/profile', params: {
      'token': _token,
    });

    if (profile['status']) {
      _totalPage = await _dbhelper.queryRowCount('accident');
      _listAccident = await _dbhelper.queryAllRows('accident');
      _listLaka = await _dbhelper.queryAllRows('laka');
      print(_listLaka);
    } else if (mounted) {
      _totalPage = await _dbhelper.queryRowCount('accident');
      _listAccident = await _dbhelper.queryAllRows('accident');
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('IRSMS'),
                content: const Text(
                    'Anda dalam mode offline ! pastikan saat sinkronisasi data anda dalam mode online (terkoneksi internet)'),
                actions: [
                  TextButton(
                      onPressed: () {
                        if (profile['error'] == 'Expired token') {
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

  Future<void> _sinkronisasi() async {
    setState(() {
      _isLoading = true;
    });
    // List pictures = await _dbhelper.queryRows(
    // table: 'pictures', where: "accidentUuid = '$accidentUuid'");

    List accidents = await _dbhelper.queryAllRows('accident');
    // print(accidents);

    for (var element in accidents) {
      var accidentUuid = element['accidentUuid'];

      //   //
      //   // Upload photos
      // List<String> paths = [];

      //   for (var path in jsonDecode(pictures[0]['path'])) {
      //     paths.add(path.toString());
      //   }

      //  uploads = await RestClient().uploadPhotos(paths);

      //   if (mounted &&
      //       (uploads['status'] == false || uploads['status'] == 'false')) {
      //     showDialog(
      //         context: context,
      //         builder: (context) {
      //           return StatefulBuilder(
      //             builder: ((context, setState) {
      //               return AlertDialog(
      //                 title: const Text('IRSMS'),
      //                 content: Text(uploads['error'].toString()),
      //                 actions: [
      //                   TextButton(
      //                       onPressed: () {
      //                         Navigator.of(context).pop();
      //                       },
      //                       child: const Text('Tutup'))
      //                 ],
      //               );
      //             }),
      //           );
      //         });

      //     continue;
      //   }
      // }

      String saksiJson = jsonEncode([]);

      // String informasiKhusus = element['informasiKhusus'];
      // bool tidakAdaSaksi =
      //     informasiKhusus.contains(RegExp(r'Tidak Ada Saksi'));
      // if (!tidakAdaSaksi) {
      //   List saksi = await _dbhelper.queryRows(
      //       table: 'saksi', where: "accidentUuid = '$accidentUuid'");

      //   if (saksi.isEmpty) {
      //     showDialog(
      //         context: context,
      //         builder: (context) {
      //           return StatefulBuilder(
      //             builder: ((context, setState) {
      //               return AlertDialog(
      //                 title: const Text('IRSMS'),
      //                 content: Text(
      //                     'Kecelakaan tanggal ${element['tanggalKejadian']} belum ada saksi.'),
      //                 actions: [
      //                   TextButton(
      //                       onPressed: () {
      //                         Navigator.of(context).pop();
      //                       },
      //                       child: const Text('Tutup'))
      //                 ],
      //               );
      //             }),
      //           );
      //         });
      //     continue;
      //   }

      //   saksiJson = jsonEncode(saksi);
      // }

      final DateTime timestamp = DateTime.now();

      // if (respp['status']) {}

      var data = {
        'uuid': accidentUuid,
        'latitude': element['latitude'],
        'longitude': element['longitude'],
        'petugas': element['petugas'],
        'nrp': element['nrp'],
        'polda': element['polda'],
        'polres': element['polres'],
        'tanggal_kejadian': element['tanggalKejadian'],
        'jam_kejadian': element['jamKejadian'],
        'tanggal_laporan': element['tanggalLaporan'],
        'jam_laporan': element['jamLaporan'],
        //    'informasi_khusus': element['informasiKhusus'],
        //  'kecelakaan_menonjol': element['kecelakaanMenonjol'],
        'tipe_kecelakaan': element['tipeKecelakaan'],
        'kondisi_cahaya': element['kondisiCahaya'],
        'cuaca': element['cuaca'],
        //    'kerusakan_material': element['kerusakanMaterial'],
        'nilai_rugi_kendaraan': element['nilaiRugiKendaraan'],
        'nilai_rugi_non_kendaraan': element['nilaiRugiNonKendaraan'],
        //  'gambar': 'jhjahjaha',
        'tkp_laka': element['tkpLaka'],
        // 'saksi': saksiJson,
        'created_at': timestamp.toString(),
        'updated_at': timestamp.toString(),
      };

      var controller = 'petugas/accident';

      var response = await RestClient()
          .post(controller: controller, data: data, token: _token);

      ///  print(response);
      var url = 'accident_pic';
      for (int i = 0; i < widget.imageUrls.length; i++) {
        var reso =
            await RestClient().uploadPhotosTkpLaka([widget.imageUrls[i]!]);
        // print(reso['rows'][0]['file_name']);
        String fileName = reso['rows'][0]['file_name'];
        var picData = {
          'accident_id': accidentUuid,
          'path': fileName
          // 'created_at': '2024-05-02 08:08:08',
          // 'updated_at': '2024-05-02 08:08:08'
        };

        var resss = await RestClient().post(controller: url, data: picData);
        print(resss);
      }

      if (mounted &&
          (response['status'] == false || response['status'] == 'false')) {
        showDialog(
            context: context,
            builder: (context) {
              return StatefulBuilder(
                builder: ((context, setState) {
                  return AlertDialog(
                    title: const Text('IRSMS'),
                    content: Text(response['error'].toString()),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Tutup'))
                    ],
                  );
                }),
              );
            });

        continue;
      }
      // if (response['status'] == true) {
      //   List pictures = await _dbhelper.queryRows(
      //       table: 'pictures', where: "accidentUuid = '$accidentUuid'");
      //   print(pictures);
      //   var url = 'accident_pic';
      //   for (var picture in pictures) {
      //     var picData = {
      //       'accident_id': accidentUuid,
      //       'path': picture['path']
      //       // 'created_at': '2024-05-02 08:08:08',
      //       // 'updated_at': '2024-05-02 08:08:08'
      //     };
      //     //   print("hgfhgf$picData");

      //     //  if (pictures.isNotEmpty) {
      //     //      print('hallo');
      //     var resss = await RestClient().post(controller: url, data: picData);
      //     // print(resss);
      //   }
      // }

      var delete = await _dbhelper.delete(
          table: 'accident',
          columnPK: 'accidentUuid',
          whereArgs: [accidentUuid]);

      if (delete != 0) {
        //
        // delete picture record
        await _dbhelper.delete(
            table: 'pictures',
            columnPK: 'accidentUuid',
            whereArgs: [accidentUuid]);

        // delete saksi record
        await _dbhelper.delete(
            table: 'saksi',
            columnPK: 'accidentUuid',
            whereArgs: [accidentUuid]);

        _totalPage = await _dbhelper.queryRowCount('accident');
        _listAccident = await _dbhelper.queryAllRows('accident');

        setState(() {});
      }
    }

    setState(() {
      _isLoading = false;
    });
  }
}

class LakaTile extends StatefulWidget {
  final Map<String, dynamic> accidentModel;
  final Function onDelete;

  const LakaTile(
      {required this.accidentModel, required this.onDelete, super.key});

  @override
  State<LakaTile> createState() => _LakaTileState();
}

class _LakaTileState extends State<LakaTile> {
  late Dbhelper _dbhelper;
  final List<Map<String, dynamic>> _pictures = [];

  @override
  void initState() {
    _dbhelper = Dbhelper();
    // _dbhelper.initializeDB().whenComplete(() async {
    //   var accidentUuid = widget.accidentModel['accidentUuid'];
    //   _pictures = await _dbhelper.queryRows(
    //       table: 'pictures', where: "accidentUuid = '$accidentUuid'");
    //   setState(() {});
    // });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // String picture = '';
    // if (_pictures.isNotEmpty) {
    //   List json = jsonDecode(_pictures[0]['path']);
    //   if (json.isNotEmpty) {
    //     picture = json[0];
    //   }
    // }

    return Card(
        elevation: 10,
        child: InkWell(
          onTap: () {},
          child: PreferredSize(
              preferredSize: const Size(double.infinity, double.infinity),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: SvgPicture.asset(
                                'assets/accident_diagrams/${widget.accidentModel['tipeKecelakaan']}.svg',
                                placeholderBuilder: (context) =>
                                    const CircularProgressIndicator(),
                              ),
                            ),
                            const SizedBox(
                              width: 8.0,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TKP Laka: ${widget.accidentModel['tkpLaka']}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  Text(
                                    'Latlng: ${widget.accidentModel['latitude']}, ${widget.accidentModel['longitude']}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  Text(
                                    'Polda/Polres: ${widget.accidentModel['polda']}/${widget.accidentModel['polres']}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  Text(
                                    'Petugas Pelapor: ${widget.accidentModel['petugas']}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return StatefulBuilder(
                                          builder: ((context, setState) {
                                            return AlertDialog(
                                              title: const Text('IRSMS'),
                                              content: const Text(
                                                  'Data yang dihapus tidak dapat dikembalikan. Yakin menghapus data?'),
                                              actions: [
                                                TextButton(
                                                    onPressed: () async {
                                                      // delete accident record
                                                      var delete =
                                                          await _dbhelper.delete(
                                                              table: 'accident',
                                                              columnPK:
                                                                  'accidentUuid',
                                                              whereArgs: [
                                                            widget.accidentModel[
                                                                'accidentUuid']
                                                          ]);
                                                      if (delete != 0) {
                                                        // delete picture record
                                                        await _dbhelper.delete(
                                                            table: 'pictures',
                                                            columnPK:
                                                                'accidentUuid',
                                                            whereArgs: [
                                                              widget.accidentModel[
                                                                  'accidentUuid']
                                                            ]);

                                                        // delete saksi record
                                                        await _dbhelper.delete(
                                                            table: 'saksi',
                                                            columnPK:
                                                                'accidentUuid',
                                                            whereArgs: [
                                                              widget.accidentModel[
                                                                  'accidentUuid']
                                                            ]);

                                                        widget.onDelete();
                                                      }

                                                      await Future.delayed(
                                                          const Duration(
                                                              seconds: 0));

                                                      if (!mounted) return;
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child:
                                                        const Text('Hapus!')),
                                                TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text('Batal'))
                                              ],
                                            );
                                          }),
                                        );
                                      });
                                },
                                style: TextButton.styleFrom(
                                    minimumSize: Size.zero,
                                    padding: EdgeInsets.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap),
                                child: const Icon(Icons.cancel_presentation)),
                            const SizedBox(
                              width: 8.0,
                            ),
                            // TextButton(
                            //   onPressed: () {
                            //     Navigator.push(
                            //         context,
                            //         MaterialPageRoute(
                            //             builder: (context) => TambahData(
                            //                 accidentUuid: widget
                            //                     .accidentModel['accidentUuid'],
                            //                 accidentData: widget.accidentModel,
                            //                 imagePath: widget.accidentModel)));
                            //   },
                            //   style: TextButton.styleFrom(
                            //       minimumSize: Size.zero,
                            //       padding: EdgeInsets.zero,
                            //       tapTargetSize:
                            //           MaterialTapTargetSize.shrinkWrap),
                            //   child: const Icon(Icons.edit_note),
                            // )
                          ],
                        ),
                        const SizedBox(
                          height: 8.0,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                              border: Border(
                                  top: BorderSide(
                                      width: 1,
                                      color: Theme.of(context).primaryColor))),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.accidentModel['tanggalKejadian'],
                                  style: const TextStyle(
                                      color: Colors.blue, fontSize: 10),
                                ),
                              ]),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ));
  }
}
