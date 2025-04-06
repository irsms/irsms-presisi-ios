import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/rest_client.dart';
import 'informasi.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'pdf_viewer_page.dart';

class LandasanHukum extends StatefulWidget {
  const LandasanHukum({super.key});

  @override
  State<LandasanHukum> createState() => _LandasanHukumState();
}

class _LandasanHukumState extends State<LandasanHukum> {
  String _token = '';
  Map<String, dynamic> _profile = {};

  final List<Info> _info = [];

  late Directory _directoryDownloads;

  Future<dynamic> tokenExpiredAlert(Map<String, dynamic> response) {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('IRSMS'),
              content: Text(response['error']),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/');
                    },
                    child: const Text('OK'))
              ],
            ));
  }

  Future<void> _initPlatformState() async {
    _setPath();
    if (!mounted) return;
  }

  void _setPath() async {
    Directory path = await getApplicationDocumentsDirectory();
    String localPath = '${path.path}${Platform.pathSeparator}Downloads';
    final savedDir = Directory(localPath);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }

    _directoryDownloads = Directory(localPath);
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      _initPlatformState();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token') ?? '';

      var profile =
          await RestClient().get(controller: 'masyarakat/profile', params: {
        'token': _token,
      });

      if (profile['status']) {
        setState(() {
          _profile = profile['rows'][0];
        });

        var controller = 'masyarakat/legislation';
        var params = {'token': _token};
        var legislation =
            await RestClient().get(controller: controller, params: params);

        if (legislation['status']) {
          int i = 0;
          legislation['rows'].forEach((row) {
            i++;
            setState(() {
              _info.add(
                Info(
                  leading: i.toString(),
                  title: row['title'],
                  legislation_id: row['legislation_id'],
                  document: row['document'] == null || row['document'] == ''
                      ? ''
                      : ("${RestClient().baseURL}/${row['document']}"),
                ),
              );
            });
          });
        }
      } else {
        if (!mounted) return;

        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('IRSMSS'),
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
        title: const Text('Dasar Hukum'),
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
                      child: TextButton(
                        onPressed: () => {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: ((context) => const Informasi())))
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
                      child: TextButton(
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
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Card(
          elevation: 10,
          child: PreferredSize(
            preferredSize: const Size(double.infinity, double.infinity),
            child: ListView(
              children: [
                ..._info.map((i) => InfoTile(
                      info: i,
                      onPressed: () async {
                        if (i.title ==
                            'UU NO.33 TAHUN 1964 TENTANG DANA PERTANGGUNGAN WAJIB KECELAKAAN PENUMPANG') {
                          const url =
                              "https://irsms.korlantas.polri.go.id/irsmsmobile/uploads/legislation/UU Nomor 33 Tahun 1964.pdf";
                          final file = await loadPdfFromNetwork(url);

                          openPdf(context, file, url);
                        } else if (i.title ==
                            'UU NO.34 TAHUN 1964 TENTANG DANA KECELAKAAN LALU LINTAS JALAN') {
                          const url =
                              "https://irsms.korlantas.polri.go.id/irsmsmobile/uploads/legislation/UU Nomor 34 Tahun 1964.pdf";
                          final file = await loadPdfFromNetwork(url);
                          openPdf(context, file, url);
                        } else if (i.title ==
                            'UU NOMOR 11 TAHUN 2008 TENTANG INFORMASI DAN TRANSAKSI ELEKTRONIK') {
                          const url =
                              "https://irsms.korlantas.polri.go.id/irsmsmobile/uploads/legislation/UU Nomor 11 Tahun 2008.pdf";
                          final file = await loadPdfFromNetwork(url);
                          openPdf(context, file, url);
                        } else if (i.title ==
                            'UU NO 22 TAHUN 2009 TENTANG LALU LINTAS DAN ANGKUTAN JALAN') {
                          const url =
                              "https://irsms.korlantas.polri.go.id/irsmsmobile/uploads/legislation/UU Nomor 22 Tahun 2009.pdf";
                          final file = await loadPdfFromNetwork(url);
                          openPdf(context, file, url);
                        } else if (i.title ==
                            'PERPRES NO.64 TAHUN 2020 TENTANG JAMINAN KESEHATAN') {
                          const url =
                              "https://irsms.korlantas.polri.go.id/irsmsmobile/uploads/legislation/Perpres Nomor 64 Tahun 2020.pdf";
                          final file = await loadPdfFromNetwork(url);
                          openPdf(context, file, url);
                        } else if (i.title ==
                            'PP NO.17 TAHUN 1965 TENTANG KETENTUAN PELAKSANAAN DANA KECELAKAAN LALU LINTAS') {
                          const url =
                              "https://irsms.korlantas.polri.go.id/irsmsmobile/uploads/legislation/PP Nomor 17 Tahun 1965.pdf";
                          final file = await loadPdfFromNetwork(url);
                          openPdf(context, file, url);
                        } else if (i.title ==
                            'PP NO.18 TAHUN 1965 TENTANG KETENTUAN PELAKSANAAN DANA KECELAKAAN LALU LINTAS') {
                          const url =
                              "https://irsms.korlantas.polri.go.id/irsmsmobile/uploads/legislation/PP Nomor 18 Tahun 1965.pdf";
                          final file = await loadPdfFromNetwork(url);
                          openPdf(context, file, url);
                        } else {
                          const url =
                              "https://irsms.korlantas.polri.go.id/irsmsmobile/uploads/legislation/Permenkeu-141 PMK-2018.pdf";
                          final file = await loadPdfFromNetwork(url);
                          openPdf(context, file, url);
                        }
                      },
                      // () async {
                      //   if (i.document == '') {
                      //     ScaffoldMessenger.of(context).showSnackBar(
                      //         const SnackBar(
                      //             content: Text('Berkas tidak tersedia.')));
                      //     return;
                      //   }

                      //   try {
                      //     Dio dio = Dio();

                      //     String filename = i.document
                      //         .substring(i.document.lastIndexOf('/') + 1);
                      //     String savePath = _directoryDownloads.path +
                      //         Platform.pathSeparator +
                      //         filename;

                      //     await dio.download(
                      //       i.document,
                      //       savePath,
                      //       onReceiveProgress: (count, total) {
                      //         showDialog(
                      //             context: context,
                      //             builder: (context) {
                      //               return const Dialog(
                      //                   backgroundColor: Colors.transparent,
                      //                   child: Center(
                      //                       child:
                      //                           CircularProgressIndicator()));
                      //             });

                      //         if (count == total) {
                      //           Navigator.pop(context);
                      //         }
                      //       },
                      //     );

                      //     await Future.delayed(const Duration(seconds: 0));
                      //     if (!mounted) return;

                      //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      //         content: Text('Download $savePath selesai.')));
                      //   } catch (e) {
                      //     ScaffoldMessenger.of(context).showSnackBar(
                      //         SnackBar(content: Text('Error: $e')));
                      //   }
                      // },
                    ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<File> loadPdfFromNetwork(String url) async {
  final response = await http.get(Uri.parse(url));
  final bytes = response.bodyBytes;
  return _storeFile(url, bytes);
}

void openPdf(BuildContext context, File file, String url) =>
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(
          file: file,
          url: url,
        ),
      ),
    );

Future<File> _storeFile(String url, List<int> bytes) async {
  String filename = url;
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/dokumen.pdf');
  await file.writeAsBytes(bytes, flush: true);
  // if (kDebugMode) {
  //   print('$file');
  // }
  return file;
}

class InfoTile extends StatelessWidget {
  final Info info;
  final Function()? onPressed;

  const InfoTile({required this.info, this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(info.leading),
      title: Row(
        children: [
          Expanded(
            child: Text(
              info.title,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          TextButton(onPressed: onPressed, child: const Icon(Icons.visibility))
        ],
      ),
    );
  }
}

class Info {
  final String leading;
  final String legislation_id;
  final String title;
  final String document;

  Info(
      {required this.leading,
      required this.title,
      required this.document,
      required this.legislation_id});
}
