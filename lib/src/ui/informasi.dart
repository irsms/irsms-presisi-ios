import 'dart:convert';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_irsms/src/ui/desktop.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/rest_client.dart';
import 'landasan_hukum.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class Informasi extends StatefulWidget {
  const Informasi({super.key});

  @override
  State<Informasi> createState() => _InformasiState();
}

class _InformasiState extends State<Informasi> {
  String _token = '';
  // Ambil ID

  bool _isLoading = true;
  Map<String, dynamic> _statistics = <String, dynamic>{};
  List<FlSpot> _chartData = [];
  final List _infoCard = [
    const InfoCard(
        name: 'Laka Pengguna', icon: Icons.directions_run, total: '0'),
    const InfoCard(name: 'Laka Hari Ini', icon: Icons.car_crash, total: '0'),
    const InfoCard(name: 'Korban Meninggal', icon: Icons.bed, total: '0'),
    const InfoCard(name: 'Total Laka', icon: Icons.local_hospital, total: '0'),
  ];

  Future<void> fetchData() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    // Mengecek koneksi internet
    if (connectivityResult == ConnectivityResult.none) {
      // Jika tidak ada koneksi, gunakan data cache
      //    await loadCachedData();

      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('IRSMS'),
                content: const Text('tidak ada koneksi interner'),
                actions: [
                  ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'))
                ],
              ));
      //    tokenExpiredAlert();
      return;
    }

    // Jika ada koneksi, lanjutkan fetch data dan simpan di cache setelahnya
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';
    var id = prefs.getString('id_register') ?? '';
    var params = {'token': _token};
    var controller = 'masyarakat/riwayat_kecelakaan';

    var riwayatKecelakaan =
        await RestClient().get(controller: controller, params: params);

    if (riwayatKecelakaan['status']) {
      setState(() {
        _infoCard[0] = InfoCard(
            name: 'Laka Pengguna',
            icon: Icons.directions_run,
            total: '${riwayatKecelakaan['rows'].length}');
      });
      // Simpan data ke cache
      prefs.setString('infoCard0', '${riwayatKecelakaan['rows'].length}');
    } else {
      tokenExpiredAlert(riwayatKecelakaan);
    }

    String cdate = DateFormat("yyyy-MM-dd").format(DateTime.now());
    Map<String, dynamic> resToday =
        await RestClient().sipulanCount(token: _token, start: cdate);

    if (resToday['status']) {
      setState(() {
        _infoCard[1] = InfoCard(
            name: 'Laka Hari Ini',
            icon: Icons.car_crash,
            total: resToday['total'].toString());
      });
      prefs.setString('infoCard1', resToday['total'].toString());
    } else {
      tokenExpiredAlert(resToday);
    }

    var now = DateTime.now();
    var start = DateTime(now.year, 1, 1).toString().substring(0, 10);
    Map<String, dynamic> resYear = await RestClient()
        .sipulanCount(token: _token, start: start, end: cdate);

    if (resYear['status']) {
      setState(() {
        _infoCard[3] = InfoCard(
            name: 'Total Laka ${now.year.toString()}',
            icon: Icons.local_hospital,
            total: resYear['total'].toString());
      });
      prefs.setString('infoCard3', resYear['total'].toString());
    } else {
      tokenExpiredAlert(resYear);
    }

    _statistics = await RestClient()
        .sipulanStatistics(token: _token, start: start, end: cdate);

    if (_statistics['status']) {
      //   print(_statistics['rows']);
      _isLoading = false;
      int totalMd = 0;
      List<FlSpot> spots = [];

      _statistics['rows'].forEach((row) {
        double bulan = double.tryParse(row['bulan'].toString()) ?? 0;
        double totalLaka = double.tryParse(row['total_laka'].toString()) ?? 0;
        spots.add(FlSpot(bulan, totalLaka));
      });

      setState(() {
        _chartData = spots;
      });

      // Menyimpan data _chartData sebagai cache
      // prefs.setString('chartData',
      //     jsonEncode(spots.map((e) => {'x': e.x, 'y': e.y}).toList()));

      _statistics['rows'].forEach((row) {
        totalMd += int.parse(row['md']);
      });

      setState(() {
        _infoCard[2] = InfoCard(
            name: 'Korban Meninggal',
            icon: Icons.bed,
            total: totalMd.toString());
      });
      prefs.setString('infoCard2', totalMd.toString());
    } else {
      tokenExpiredAlert(_statistics);
    }
  }

  Future<void> loadCachedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _infoCard[0] = InfoCard(
          name: 'Laka Pengguna',
          icon: Icons.directions_run,
          total: prefs.getString('infoCard0') ?? '0');
      _infoCard[1] = InfoCard(
          name: 'Laka Hari Ini',
          icon: Icons.car_crash,
          total: prefs.getString('infoCard1') ?? '0');
      _infoCard[2] = InfoCard(
          name: 'Korban Meninggal',
          icon: Icons.bed,
          total: prefs.getString('infoCard2') ?? '0');
      _infoCard[3] = InfoCard(
          name: 'Total Laka Tahun Ini',
          icon: Icons.local_hospital,
          total: prefs.getString('infoCard3') ?? '0');

      // Membaca dan memuat data chart dari cache
      String? cachedChartData = prefs.getString('chartData');
      if (cachedChartData != null) {
        List<dynamic> cachedSpots = jsonDecode(cachedChartData);
        _chartData = cachedSpots.map((e) => FlSpot(e['x'], e['y'])).toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, fetchData);
  }

  Future<dynamic> tokenExpiredAlert(Map<String, dynamic> response) {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('IRSMS'),
              content: Text(response['error']),
              actions: [
                ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        // leading: IconButton(
        //     icon: const Icon(Icons.arrow_back),
        //     onPressed: () async {
        //       SharedPreferences prefs = await SharedPreferences.getInstance();
        //       String? _id = prefs.getString('_idRegister');
        //       Navigator.pushAndRemoveUntil(
        //         context,
        //         MaterialPageRoute(
        //           builder: (context) => Desktop(id: _id),
        //         ),
        //         (route) => false, // Menghapus semua halaman sebelumnya
        //       );
        //     }),
        title: const Text('Informasi'),
        bottom: PreferredSize(
            preferredSize: const Size(double.infinity, 1.5 * kToolbarHeight),
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4.0, bottom: 8.0),
                      child: ElevatedButton(
                        onPressed: () => {setState(() {})},
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(
                              Theme.of(context).primaryColor),
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.all(16)),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Laka',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                      child: ElevatedButton(
                        onPressed: () => {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: ((context) =>
                                      const LandasanHukum())))
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(
                            Colors.grey,
                          ),
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.all(16)),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Landasan Hukum',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator()) // Menampilkan loading indicator
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: Platform.isIOS ? 2.5 : 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      shrinkWrap: true,
                      children: List.generate(
                          4,
                          (index) => InfoCardWidget(
                                infoCard: _infoCard[index],
                              )).toList(),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    const Text('Statistik'),
                    const Text(
                      'Jumlah Laka',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      width: double.infinity,
                      height: 250,
                      margin: const EdgeInsets.only(top: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: const Color.fromARGB(255, 5, 13, 218)),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: LineChart(
                          LineChartData(
                            lineBarsData: [
                              LineChartBarData(
                                spots: _chartData,
                                color: Color.fromARGB(255, 0, 16, 123),
                                isCurved: true,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(show: false),
                              ),
                            ],
                            // minY: 5000,
                            lineTouchData: LineTouchData(
                                getTouchedSpotIndicator:
                                    (barData, spotIndexes) {
                              return spotIndexes.map((index) {
                                return const TouchedSpotIndicatorData(
                                  FlLine(
                                      color: Color.fromARGB(255, 255, 255, 255),
                                      strokeWidth: 2),
                                  FlDotData(show: true),
                                );
                              }).toList();
                            }, touchTooltipData: LineTouchTooltipData(
                              //   tooltipBgColor: Colors.blueAccent,
                              getTooltipItems:
                                  (List<LineBarSpot> touchedSpots) {
                                var f = NumberFormat('#,###', 'en_US');
                                return touchedSpots
                                    .map((LineBarSpot touchedSpot) {
                                  return LineTooltipItem(
                                    '${f.format(touchedSpot.y)} Laka',
                                    const TextStyle(
                                        color:
                                            Color.fromARGB(255, 255, 255, 255)),
                                  );
                                }).toList();
                              },
                            )),
                            maxY: _chartData
                                    .map((e) => e.y)
                                    .reduce((a, b) => a > b ? a : b) +
                                1000,
                            gridData: const FlGridData(
                              show: true, // Menampilkan grid (garis bantu)
                            ),
                            borderData: FlBorderData(
                              show:
                                  false, // Menghilangkan garis kotak di sekeliling chart
                            ),

                            titlesData: const FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: bottomTitles,
                                  interval: 1,
                                  reservedSize: 30,
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: false,
                                  reservedSize:
                                      50, // Menghilangkan angka di atas chart
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles:
                                      false, // Menghilangkan angka di sumbu kanan
                                ),
                              ),

                              // leftTitles: const AxisTitles(
                              //   sideTitles: SideTitles(
                              //     showTitles:
                              //         false, // Menghilangkan angka di sumbu kanan
                              //   ),
                              // ),
                            ),
                            //  clipData: const FlClipData.all(),
                            // Memastikan garis tidak keluar dari area chart
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    // const Text('Jumlah Laka'),
                    const Text(
                      'Korban Kecelakaan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // Container(
                    //   width: double.infinity,
                    //   height: 200,
                    //   margin: const EdgeInsets.only(top: 8.0),
                    //   decoration: BoxDecoration(
                    //     color: Colors.white,
                    //     border: Border.all(
                    //         color: const Color.fromARGB(255, 5, 13, 218)),
                    //     borderRadius: BorderRadius.circular(8.0),
                    //   ),
                    //   child: StackedFillColorBarChart.create(
                    //     data: _statistics['rows'],
                    //   ),
                    // ),
                    // const SizedBox(
                    //   height: 32,
                    // ),
                    Container(
                      width: double.infinity,
                      height: 400,
                      margin: const EdgeInsets.only(top: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: const Color.fromARGB(255, 5, 13, 218)),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: const EdgeInsets.all(40.0),
                      child: BarChart(
                        BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            barGroups: _statistics['rows']
                                .map<BarChartGroupData>((data) {
                              // Mengonversi 'bulan' dan 'md' menjadi tipe data yang sesuai
                              int bulan = int.parse(data['bulan']
                                  .toString()); // Pastikan 'bulan' adalah integer
                              double md = double.parse(data['md'].toString());
                              double lb = double.parse(data['lb'].toString());
                              double lr = double.parse(data['lr'].toString());
                              // Pastikan 'md' adalah double

                              return BarChartGroupData(
                                x: bulan, // Menggunakan 'bulan' untuk sumbu X
                                barRods: [
                                  BarChartRodData(
                                    toY:
                                        md, // Menggunakan nilai 'md' untuk sumbu Y
                                    color: Color.fromARGB(
                                        255, 20, 15, 163), // Warna batang
                                    width: 15, // Lebar batang
                                  ),
                                  // Batang untuk lb
                                  BarChartRodData(
                                    toY: lb, // Nilai Y untuk 'lb'
                                    color: Color.fromARGB(
                                        255, 77, 131, 248), // Warna batang lb
                                    width: 15, // Lebar batang lb
                                  ),
                                  //    Batang untuk lr
                                  // BarChartRodData(
                                  //   toY: lr, // Nilai Y untuk 'lr'
                                  //   color: Color.fromARGB(
                                  //       255, 53, 105, 235), // Warna batang lr
                                  //   width: 18, // Lebar batang lr
                                  // ),
                                ],
                              );
                            }).toList(),
                            gridData: const FlGridData(show: true),
                            titlesData: const FlTitlesData(
                                show: true,
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: bottomTitles,
                                  ),
                                )

                                // Menampilkan judul sumbu X
                                ),
                            borderData: FlBorderData(show: false),
                            barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) =>
                                  Color.fromARGB(255, 116, 116, 116),
                              tooltipHorizontalAlignment:
                                  FLHorizontalAlignment.right,
                              tooltipMargin: -10,
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                // Menampilkan tooltip dengan label 'MD' atau 'LB' tergantung batang yang dipilih
                                String label = rodIndex == 0 ? 'MD' : 'LB';
                                int value = rod.toY.toInt();

                                return BarTooltipItem(
                                  // '$label: $value',
                                  '$value $label',
                                  const TextStyle(
                                      color:
                                          Color.fromARGB(255, 255, 255, 255)),
                                );
                              },
                            ))
                            // Menampilkan border pada grafik
                            ),
                      ),
                    ),
                    const SizedBox(
                      height: 32,
                    )
                  ],
                ),
              ),
            ),
    );
  }
}

Widget bottomTitles(double value, TitleMeta meta) {
  const style = TextStyle(fontSize: 10);
  String text;
  switch (value.toInt()) {
    case 1:
      text = 'Jan';
      break;
    case 2:
      text = 'Feb';
      break;
    case 3:
      text = 'Mar';
      break;
    case 4:
      text = 'Apr';
      break;
    case 5:
      text = 'Mei';
      break;
    case 6:
      text = 'Jun';
      break;
    case 7:
      text = 'Jul';
      break;
    case 8:
      text = 'Aug';
      break;
    case 9:
      text = 'Sep';
      break;
    case 10:
      text = 'Okt';
      break;
    case 11:
      text = 'Nov';
      break;
    case 12:
      text = 'Des';
      break;
    default:
      text = '';
      break;
  }
  return SideTitleWidget(
    axisSide: meta.axisSide,
    child: Text(text, style: style),
  );
}

class InfoCardWidget extends StatelessWidget {
  final InfoCard? infoCard;

  const InfoCardWidget({this.infoCard, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(width: 1, color: Theme.of(context).primaryColor),
          borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  infoCard!.icon,
                  color: const Color.fromARGB(255, 1, 74, 107),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    NumberFormat('#,###', 'id-ID')
                        .format(int.parse(infoCard!.total)),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  AutoSizeText(infoCard!.name),
                ],
              )
            ]),
      ),
    );
  }
}

class InfoCard {
  final String name;
  final IconData icon;
  final String total;

  const InfoCard({required this.name, required this.icon, required this.total});
}

class PointsLineChart extends StatelessWidget {
  final List<charts.Series<dynamic, int>> seriesList;
  final bool animate;

  const PointsLineChart(this.seriesList, {this.animate = false, super.key});

  factory PointsLineChart.create({List? data}) {
    return PointsLineChart(
      _createData(rawData: data),
      animate: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return charts.LineChart(
      seriesList,
      animate: animate,
      defaultRenderer: charts.LineRendererConfig(includePoints: true),
      // behaviors: [charts.SeriesLegend()],
    );
  }

  static List<charts.Series<ChartsModel, int>> _createData({List? rawData}) {
    final data = <ChartsModel>[];

    if (rawData != null) {
      for (var e in rawData) {
        data.add(
            ChartsModel(int.parse(e['bulan']), int.parse(e['total_laka'])));
      }
    }

    return [
      charts.Series<ChartsModel, int>(
          id: 'Laka',
          colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
          domainFn: (ChartsModel chartsModel, _) => chartsModel.id,
          measureFn: (ChartsModel chartsModel, _) => chartsModel.total,
          data: data),
    ];
  }
}

class StackedFillColorBarChart extends StatelessWidget {
  final List<charts.Series<dynamic, String>> seriesList;
  final bool animate;

  const StackedFillColorBarChart(this.seriesList,
      {this.animate = true, super.key});

  factory StackedFillColorBarChart.create({List? data}) {
    return StackedFillColorBarChart(
      _createData(rawData: data),
      animate: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return charts.BarChart(
      seriesList,
      animate: animate,
      defaultRenderer: charts.BarRendererConfig(
          groupingType: charts.BarGroupingType.stacked, strokeWidthPx: 2.0),
      // behaviors: [charts.SeriesLegend()],
    );
  }

  static List<charts.Series<ChartsModel, String>> _createData({List? rawData}) {
    final data = <ChartsModel>[];

    if (rawData != null) {
      for (var e in rawData) {
        data.add(ChartsModel(int.parse(e['bulan']), int.parse(e['md'])));
      }
    }

    return [
      charts.Series<ChartsModel, String>(
        id: 'Meninggal Dunia',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (ChartsModel chartsModel, _) => chartsModel.id.toString(),
        measureFn: (ChartsModel chartsModel, _) => chartsModel.total,
        data: data,
        fillColorFn: (_, __) =>
            charts.MaterialPalette.blue.shadeDefault.lighter,
      ),
    ];
  }
}

class ChartsModel {
  final int id;
  final int total;
  ChartsModel(this.id, this.total);
}
