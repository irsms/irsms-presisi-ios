import 'package:flutter_application_irsms/src/services/rest_client_petugas.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_pagination/flutter_pagination.dart';
import 'package:flutter_pagination/widgets/button_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../libraries/colors.dart' as my_colors;
import '../models/laka_model_petugas.dart';
import '../services/rest_client.dart';
import 'form_lapor_petugas.dart';
import 'lapor_detail_petugas.dart';

class LaporLakaPetugas extends StatefulWidget {
  const LaporLakaPetugas({super.key});

  @override
  State<LaporLakaPetugas> createState() => _LaporLakaPetugasState();
}

class _LaporLakaPetugasState extends State<LaporLakaPetugas> {
  String _token = '';
  String namaDati = '';

  int _totalPage = 0;
  int _totalPagination = 0;

  int _currentPage = 1;

  final List<String> _categories = [];

  final List _isSelected = List.generate(5, (index) => [false]);

  Future<void> fetchCategories() async {
    var controller = 'accident_category';
    var params = {'token': _token};
    var resp = await RestClient().get(controller: controller, params: params);
    if (resp['status']) {
      resp['rows'].forEach((row) => _categories.add(row['accident_category']));
    }
  }

  Future<void> fetchStatuses() async {
    var controller = 'accident_statuses';
    var params = {'token': _token};
    var resp = await RestClient().get(controller: controller, params: params);

    if (resp['status']) {
      resp['rows'].forEach((row) => _categories.add(row['aduan_category']));
    }
  }

  int _dalamProses = 0;
  int _dataTidakSah = 0;
  int _laporanSelesai = 0;

  Future<void> _fetchTotalLaporan() async {
    var profile =
        await RestClient().get(controller: 'petugas/profile', params: {
      'token': _token,
    });
    var getWilayah = profile['rows'][0]['polres_id'];
    var wilayah = await RestClient().get(
        controller: 'ref_wilayah',
        params: {"token": _token, "polres_id": getWilayah});
    var controller = 'petugas/lapor_laka/total_by_status';
    var namaDati = wilayah['rows'][0]['nama_polres'];
    // var namaDati = 'CILACAP';
    var params = {'token': _token, 'nama_dati': namaDati};
    var resp = await RestClient().get(controller: controller, params: params);

    if (resp['status']) {
      List rows = resp['rows'];
      for (var row in rows) {
        var statusLaporan = row['status_laporan'];

        int jumlah = int.parse(row['jumlah']);

        if (statusLaporan == '1') {
          _dalamProses += jumlah;
        } else if (statusLaporan == '9') {
          _laporanSelesai += jumlah;
        } else if (statusLaporan == '0') {
          _dataTidakSah += jumlah;
        } else {
          _dalamProses += jumlah;
        }
      }
    }
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token') ?? '';

      await fetchCategories();

      for (var i = 0; i < _categories.length; i++) {
        _isSelected[i] = [false];
      }

      _fetchTotalLaporan();

      await _fetchLaporan(page: 1);

      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Lapor Laka'),
        leading: IconButton(
            onPressed: (() => Navigator.pushNamed(context, '/desktop')),
            icon: const Icon(Icons.arrow_back)),
        bottom: PreferredSize(
          preferredSize: const Size(double.infinity, 130),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: 0.75 * MediaQuery.of(context).size.width,
              child: ElevatedButton(
                onPressed: _formLapor,
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(my_colors.yellow),
                    padding:
                        MaterialStateProperty.all(const EdgeInsets.all(16)),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0)))),
                child: Text(
                  'Buat Laporan',
                  style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchCategories();
          await _fetchLaporan(page: _currentPage);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(6)),
                      child: Row(children: [
                        Container(
                          width: 20,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            '$_dalamProses',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Text(
                          ' Dalam Proses',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        )
                      ]),
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(6)),
                      child: Row(children: [
                        Container(
                          width: 20,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            '$_dataTidakSah',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Text(
                          ' Data Tidak Sah',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        )
                      ]),
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(6)),
                      child: Row(children: [
                        Container(
                          width: 20,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            '$_laporanSelesai',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Text(
                          ' Selesai',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        )
                      ]),
                    ),
                  )
                ],
              ),
              const Center(
                child: Text(
                  'Daftar Laporan',
                  style: TextStyle(
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      height: 2),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ..._categories.asMap().entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: ToggleButtons(
                            borderRadius: BorderRadius.circular(32),
                            constraints: BoxConstraints.expand(
                                width: (MediaQuery.of(context).size.width -
                                        32 * _categories.length) /
                                    _categories.length,
                                height: 32),
                            fillColor: Theme.of(context).primaryColor,
                            selectedColor: Colors.white,
                            onPressed: (index) async {
                              setState(() {
                                _isSelected[e.key][index] =
                                    !_isSelected[e.key][index];
                              });

                              await _fetchLaporan();
                            },
                            isSelected: _isSelected[e.key],
                            children: [
                              Text(
                                e.value,
                                style: const TextStyle(fontSize: 14 * .75),
                              )
                            ]),
                      );
                    })
                  ],
                ),
              ),
              // Column(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [...laka.map((i) => LakaTile(lakaModelPetugas: i))],
              // ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ...laka.take(3).map((i) => LakaTile(lakaModelPetugas: i)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: (_totalPage > 3
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
                            _fetchLaporan(page: _currentPage);
                          });
                        },
                        useGroup: false,
                        totalPage: _totalPage,
                        show: 3,
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
    );
  }

  void _formLapor() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const LaporPetugas()));
  }

  Future<void> _fetchLaporan({int? page}) async {
    var profile =
        await RestClient().get(controller: 'petugas/profile', params: {
      'token': _token,
    });
    //   print([profile]);
    var getWilayah = profile['rows'][0]['polres_id'];
    var wilayah = await RestClient().get(
        controller: 'ref_wilayah',
        params: {"token": _token, "polres_id": getWilayah});
    //   print(wilayah);
    if (profile['status']) {
      if (profile['polres_id'] != null) {
        // if (wilayah['status']) {
        //   param['satuan_kepolisian'] = wilayah['rows'][0]['nama_dati'];
        // }
      }
    }
    var namaDati = wilayah['rows'][0]['nama_polres'];
    // print(namaDati);

    if (profile['status']) {
      page ??= 1;
      var controller = 'petugas/lapor_laka_get';
      var limit = 5;
      var params = {
        'token': _token,
        'nama_dati': namaDati,
        'offset': (page - 1) * limit,
        'limit': limit,
        //  'satuan_kepolisian' : _getWilayah['rows'][0]['nama_dati']
      };
      //    print(params);

      for (var i = 0; i < _isSelected.length; i++) {
        if (_isSelected[i][0]) {
          params['category[$i]'] = _categories[i];
        }
      }

      var resp =
          await RestClientPetugas().get(controller: controller, params: params);

      //  print(resp);

      laka.clear();

      _totalPage = resp['total'].toInt();
      // print(_totalPage);
      _totalPagination = (_totalPage / limit).round();
      print(_totalPagination);

      if (resp['status']) {
        String baseUrl = RestClient().baseURL;

        resp['rows'].forEach((row) {
          // var jumlahKorban = int.parse(row['md']);
          // jumlahKorban += int.parse(row['lb']);
          // jumlahKorban += int.parse(row['lr']);

          laka.add(LakaModelPetugas(
            id: int.parse(row['petugas__lapor_laka_id']),
            tanggal: row['accident_date'],
            namaJalan: row['road_name'],
            pelaksanaTugas: row['satuan_kepolisian'],
            // petugasPelapor: row['officer_id'],
            // jumlahKorban: jumlahKorban,
            deskripsi: row['chronological'],
            gambar: "$baseUrl/${row['picture']}",
            statusLaporan: row['status_laporan'],
            kategori: row['category'],
          ));
        });

        setState(() {});
      }
    } else if (mounted) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('IRSMS'),
                content: Text(profile['error']),
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
}

class LakaTile extends StatelessWidget {
  final LakaModelPetugas lakaModelPetugas;

  const LakaTile({required this.lakaModelPetugas, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 10,
        child: InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: ((context) => LaporDetailPetugas(
                        lakaModelPetugas: lakaModelPetugas))));
          },
          child: PreferredSize(
              preferredSize: const Size(double.infinity, double.infinity),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          margin: const EdgeInsets.only(bottom: 8.0),
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      width: 1,
                                      color: Theme.of(context).primaryColor))),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  lakaModelPetugas.tanggal,
                                  style: const TextStyle(
                                      color: Colors.blue, fontSize: 10),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: Colors.blue.shade900,
                                      borderRadius: BorderRadius.circular(4)),
                                  child: Text(
                                      lakaModelPetugas.kategori ??
                                          'DALAM PROSES',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 10)),
                                ),
                              ]),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Center(
                              child: FutureBuilder<http.Response>(
                                future: http
                                    .get(Uri.parse(lakaModelPetugas.gambar)),
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

                                      if (snapshot.data!.statusCode == 200) {
                                        return SizedBox(
                                            width: 64,
                                            child: Image.memory(
                                              snapshot.data!.bodyBytes,
                                              fit: BoxFit.fitWidth,
                                            ));
                                      }

                                      return const SizedBox(
                                          width: 64,
                                          child: Icon(
                                            Icons.broken_image,
                                            color: my_colors.grey,
                                            size: 64,
                                          ));
                                  }
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        .625,
                                    child: Text(
                                      'Nama Jalan: ${lakaModelPetugas.namaJalan}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        .625,
                                    child: Text(
                                      'Polres/Polda: ${lakaModelPetugas.pelaksanaTugas}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  // SizedBox(
                                  //   width: MediaQuery.of(context).size.width *
                                  //       .625,
                                  //   child: Text(
                                  //     'Petugas Pelapor: ${lakaModel.petugasPelapor}',
                                  //     style: const TextStyle(fontSize: 13),
                                  //   ),
                                  // ),
                                  // SizedBox(
                                  //   child: Text(
                                  //     'Jumlah Korban: ${lakaModel.jumlahKorban}',
                                  //     style: const TextStyle(fontSize: 13),
                                  //   ),
                                  // ),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        .625,
                                    child: Text(
                                      'Deskripsi: ${lakaModelPetugas.deskripsi}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ));
  }
}

final laka = [];
