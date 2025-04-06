// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_irsms/src/helpers/dbhelper.dart';
import 'package:flutter_application_irsms/src/ui/desktop_petugas.dart';
import 'package:flutter_application_irsms/src/ui/ktp.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/link.dart';
import 'src/libraries/colors.dart' as my_colors;
import 'src/ui/desktop.dart';
import 'src/ui/registrasi.dart';
import 'src/ui/verifikasi_akun.dart';
import 'src/services/rest_client.dart';
import 'package:slider_captcha/slider_capchar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
// import 'package:url_launcher/link.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_update/in_app_update.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var token = localStorage.getString('token');
  final prefs = await SharedPreferences.getInstance();
  String? roleUser = prefs.getString('roleuser');
  int? id = prefs.getInt('idRegister');
  AppUpdateInfo? updateInfo;
  runApp(
    MaterialApp(
      theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: my_colors.blue,
          textTheme: GoogleFonts.poppinsTextTheme(),
          colorScheme:
              ColorScheme.fromSwatch().copyWith(background: my_colors.grey)),
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/login': (BuildContext context) => const MyHomePage(
              title: 'IRSMS',
            ),
        '/': (BuildContext context) {
          // Cek token dan roleUser untuk menentukan halaman awal
          if (token == null || roleUser == null) {
            return const MyHomePage(title: 'IRSMS'); // Halaman login
          } else if (roleUser == 'petugas') {
            return const Desktop_petugas(); // Halaman petugas
          } else if (roleUser == 'members') {
            return Desktop(id: id); // Halaman anggota
          } else {
            return const MyHomePage(title: 'IRSMS'); // Default ke halaman login
          }
        },
        '/desktop': (BuildContext context) => const Desktop_petugas(),
        '/desktop_members': (BuildContext context) => Desktop(
              id: id,
            ),
        '/signup': (BuildContext context) => const Registrasi(),
      },
      // home: token == null
      //     ? const MyHomePage(
      //         title: 'IRSMS',
      //       )
      //     : Desktop(id: id),
    ),
  );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkUserSession();
  }

  Future<void> checkUserSession() async {
    var session = await getUserSession();

    if (session != null) {
      if (isLoginExpired(session['lastLogin'])) {
        // Jika login kadaluarsa, minta login ulang
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        // Jika masih valid, langsung navigasi ke dashboard berdasarkan level user
        navigateToDashboard(session['userLevel']);
      }
    } else {
      // Jika belum login, minta login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  bool isLoginExpired(int lastLogin) {
    final oneWeek = const Duration(days: 7).inMilliseconds;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    return currentTime - lastLogin >
        oneWeek; // Cek apakah sudah lebih dari 1 minggu
  }

  void navigateToDashboard(String userLevel) {
    if (userLevel == 'petugas') {
      Navigator.pushReplacementNamed(context, '/desktop'); // Menu untuk user A
    } else if (userLevel == 'members') {
      Navigator.pushReplacementNamed(
          context, '/desktop_members'); // Menu untuk user B
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

Future<void> saveUserSession(String userLevel) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('userLevel', userLevel); // Simpan level user
  await prefs.setInt('lastLogin',
      DateTime.now().millisecondsSinceEpoch); // Simpan waktu login terakhir
}

Future<Map<String, dynamic>?> getUserSession() async {
  final prefs = await SharedPreferences.getInstance();
  String? userLevel = prefs.getString('roleuser');
  int? lastLogin = prefs.getInt('lastLogin');

  if (userLevel != null && lastLogin != null) {
    return {
      'userLevel': userLevel,
      'lastLogin': lastLogin,
    };
  }
  return null; // Jika belum ada data
}

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'IRSMS',
//       theme: ThemeData(
//           brightness: Brightness.light,
//           primaryColor: my_colors.blue,
//           textTheme: GoogleFonts.poppinsTextTheme(),
//           colorScheme:
//               ColorScheme.fromSwatch().copyWith(background: my_colors.grey)),
//       initialRoute: '/',
//       routes: <String, WidgetBuilder>{
//         '/': (BuildContext context) => const MyHomePage(
//               title: 'IRSMS',
//             ),
//         '/desktop': (BuildContext context) => const Desktop(),
//         '/signup': (BuildContext context) => const Registrasi(),
//         '/face': (BuildContext context) => FaceAuth(),
//         '/ktp': (BuildContext context) => const FaceKtp(),
//       },
//     );
//   }
// }

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  );

  String respo = '';
  late Dbhelper _dbhelper;
  // late Timer _timer;

  final LocalAuthentication auth = LocalAuthentication();
  final SliderController controller = SliderController();
  _SupportState _supportState = _SupportState.unknown;
  // bool? _canCheckBiometrics;
  // List<BiometricType>? _availableBiometrics;
  String _authorized = 'Not Authorized';
  final _petugasPelapor = {
    'nama': '-',
    'nrp': '-',
    'polda': '-',
    'polres': '-'
  };
  final Map<String, String> grpID = {
    'informasiKhusus': 'A06',
    'tipeKecalakaan': 'A07',
    'kondisiCahaya': 'A08',
    'cuaca': 'A09',
    'kecelakaanMenonjol': 'A10',
    'kerusakanMaterial': 'PRP1'
  };
  // bool _isAuthenticating = false;

  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _streamSubscription;

  String apiResponse = '';

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool showPassword = false;
  bool isLoading = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    int versionCode = int.parse(info.buildNumber);
    //  print(versionCode);
    setState(() {
      _packageInfo = info;
    });
  }

  void showSnack(String text) {
    if (_scaffoldKey.currentContext != null) {
      ScaffoldMessenger.of(_scaffoldKey.currentContext!)
          .showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<String> getLatestVersion() async {
    const packageName = 'nama_paket_flutter'; // Gantilah dengan nama paket Anda
    final response =
        await http.get('https://pub.dev/api/packages/$packageName' as Uri);

    if (response.statusCode == 200) {
      // Parsing respons JSON untuk mendapatkan versi terbaru
      final Map<String, dynamic> data = json.decode(response.body);
      final latestVersion = data['latest']['version'];
      return latestVersion;
    } else {
      throw Exception('Gagal mengambil data versi terbaru.');
    }
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('Anda yakin?'),
                  content: const Text('Anda ingin keluar dari aplikasi?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Tidak')),
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Ya')),
                  ],
                ))) ??
        false;
  }

  Future<void> postData() async {
    // Define the API endpoint URL
    final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
    const getWilayah = 'ads';

    // Define the data to be sent as a JSON object
    final data = {
      "to": "/topics/$getWilayah",
      "notification": {
        "title": "Laporan Laka Masyarakat",
        "body": "Telah Terjadi laka di jalan cikoko dengan kronologi korban md",
        "icon": "icon.png"
      },
      "data": {"key1": "value1", "key2": "value2"}
    };
    final jsonData = jsonEncode(data);

    // Send the HTTP POST request
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'key=AAAAmsaWQ6g:APA91bF4YGLZciQi4mtlWb2pb8PNkr_Gjt-5IHjn8Ur2Q-R__XkBTyLXs64crizGIBWhqvQVJgTjticbUUsCEDdvg6Z5sc36H555r_K_ZacoswIrAiNFLNZthe23tV32WeoFRBlI93Ao'
      },
      body: jsonData,
    );

    // Handle the response
    if (response.statusCode == 200) {
      print('Post request successful');
    } else {
      print('Post request failed with status: ${response.statusCode}');
    }
  }

  Future<void> _cekApi() async {
    if (_connectionStatus == ConnectivityResult.none) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_connectionStatus.toString())));
      return;
    }

    setState(() {
      isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int loginAttempt = prefs.getInt('loginAttempt') ?? 0;
    int lastLoginTime = prefs.getInt('last_login_time') ?? 0;
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    int elapsedTime = currentTime - lastLoginTime;

    var controller = '/login';
    var data = {
      'username': _usernameController.text,
      'password': _passwordController.text
    };

    var response = await RestClient().post(controller: controller, data: data);
    //  print(response['status']);
    setState(() {
      isLoading = false;
    });
    if (response['status'] == false) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('IRSMS'),
                content: const Text('username/password salah !'),
                actions: [
                  ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Tutup'))
                ],
              ));
      return;
    }
    if (response['roleUser'] == 'petugas') {
      if (response['status']) {
        prefs.setString('username', _usernameController.text);
        prefs.setString('password', _passwordController.text);
        prefs.setString('token', response['token']);
        prefs.setString('roleuser', response['roleUser']);
        prefs.setInt('lastLogin', currentTime);

        await Future.delayed(const Duration(seconds: 0));
        // var profile =
        //     await RestClient().get(controller: 'petugas/profile', params: {
        //   'token': response['token'],
        // });
        // var result = 0;
        // var polda = await RestClient().get(controller: 'polda', params: {
        //   'token': response['token'],
        //   'id': profile['rows'][0]['polda_id']
        // });
        // if (polda['total'] == 1) {
        //   _petugasPelapor['polda'] = polda['rows'][0]['name'];
        // }

        // var polres = await RestClient().get(controller: 'polres', params: {
        //   'token': response['token'],
        //   'id': profile['rows'][0]['polres_id']
        // });
        // if (polres['total'] == 1) {
        //   _petugasPelapor['polres'] = polres['rows'][0]['name'];
        // }
        // Map<String, dynamic> lakaRecord = {
        //   'id': '1', // Ubah ke string jika diperlukan
        //   'name':
        //       '${profile['rows'][0]['first_name']} ${profile['rows'][0]['last_name']}',
        //   'nrp': profile['rows'][0]['officer_id'],
        //   'polda': _petugasPelapor['polda'] = polda['rows'][0]['name'],
        //   'polres': _petugasPelapor['polres'] =
        //       polres['rows'][0]['name'], // Ubah ke string jika diperlukan
        // };
        // result = await _dbhelper.insert(
        //   table: 'laka',
        //   data: lakaRecord,
        // );
        var profile =
            await RestClient().get(controller: 'petugas/profile', params: {
          'token': response['token'],
        });
        var result = 0;
        Map<String, dynamic> polda;
        if (profile['rows'][0]['polda_id'] != null) {
          polda = await RestClient().get(controller: 'polda', params: {
            'token': response['token'],
            'id': profile['rows'][0]['polda_id']
          });
          if (polda['total'] == 1) {
            _petugasPelapor['polda'] = polda['rows'][0]['name'];
          }
        } else {
          // Jika 'polda_id' kosong, maka set 'polda' ke 'default_value'
          _petugasPelapor['polda'] = 'korlantas';
        }

        Map<String, dynamic> polres;
        if (profile['rows'][0]['polres_id'] != null) {
          polres = await RestClient().get(controller: 'polres', params: {
            'token': response['token'],
            'id': profile['rows'][0]['polres_id']
          });
          if (polres['total'] == 1) {
            _petugasPelapor['polres'] = polres['rows'][0]['name'];
          }
        } else {
          // Jika 'polres_id' kosong, maka set 'polres' ke 'korlantas'
          _petugasPelapor['polres'] = 'korlantas';
        }

        Map<String, dynamic> lakaRecord = {
          'id': '1', // Ubah ke string jika diperlukan
          'name':
              '${profile['rows'][0]['first_name']} ${profile['rows'][0]['last_name']}',
          'nrp': profile['rows'][0]['officer_id'],
          'polda':
              _petugasPelapor['polda'] ?? '', // Ubah ke string jika diperlukan
          'polres':
              _petugasPelapor['polres'] ?? '', // Ubah ke string jika diperlukan
        };
        //   print(lakaRecord);
        result = await _dbhelper.insert(
          table: 'laka',
          data: lakaRecord,
        );
        Map<String, String> params = {
          'token': 'Hy6d3K1d93LOHRfbeE0KKly1YK9t4YdGsbNDEvyxAYI=irsmsmobile'
        };

        String ref = 'ref';
        var resp = await RestClient().get(controller: ref, params: params);
        print(resp['status']);

// Iterasi setiap baris data dalam resp['rows']
        resp['rows'].forEach((e) async {
          // Memeriksa apakah grp_id adalah 'PRP1'
          if (e['grp_id'] == 'PRP1' ||
              e['grp_id'] == 'A09' ||
              e['grp_id'] == 'A07' ||
              e['grp_id'] == 'A08' ||
              e['grp_id'] == 'A10' ||
              e['grp_id'] == 'A06') {
            // Jika ya, maka data dimasukkan ke dalam database
            await _dbhelper.insert(
              table: 'ref',
              data: {
                'id': e['id'],
                'name': e['name'],
                'grp_id': e['grp_id'],
                'sort': e['sort'],
                'state': e['state'],
                // Anda bisa menambahkan properti lainnya sesuai kebutuhan
              },
            );
          }
        });

        if (elapsedTime < 30000) {
          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: const Text('IRSMS'),
                    content: const Text(
                        'anda terlalu sering login  tunggu 1 menit !'),
                    actions: [
                      ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Tutup'))
                    ],
                  ));
          return;
        }
        await Permission.locationAlways.request();
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Desktop_petugas()),
          (route) => false,
        );
        loginAttempt = 0;
      } else if (mounted) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        loginAttempt = prefs.getInt('loginAttempt') ?? 0;
        if (elapsedTime < 30000) {
          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: const Text('IRSMS'),
                    content: const Text('anda terlalu sering login !'),
                    actions: [
                      ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Tutup'))
                    ],
                  ));
          //return;
        } else {
          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: const Text('IRSMS'),
                    content: const Text('Username/password salah !'),
                    actions: [
                      ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Tutup'))
                    ],
                  ));
        }

        loginAttempt++;
      }
      prefs.setInt('loginAttempt', loginAttempt);
      if (loginAttempt >= 2) {
        prefs.setInt('last_login_time', currentTime);
      }
    }
    if (response['roleUser'] == 'members') {
      //  print('asik masook');
      if (response['status']) {
        String id = response['id'];
        if (response['ktp'] == null || response['selfie'] == null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('_idResgister', id);
          prefs.setString('roleuser', response['roleUser']);
          prefs.setInt('lastLogin', currentTime);

          // ignore: use_build_context_synchronously
          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: const Text('Upload Ulang'),
                    content: const Text(
                        'Anda belum upload foto KTP / Selfie , apakah Anda akan upload sekarang ??'),
                    actions: [
                      ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Tidak')),
                      ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const FaceKtp()),
                            );
                          },
                          child: const Text('Ya, Upload Sekarang'))
                    ],
                  ));
          return;
        }

        if (response['state'] == '0') {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('_idResgister', id);
          prefs.setString('roleuser', response['roleUser']);

          // ignore: use_build_context_synchronously
          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: const Text('Verifikasi gagal'),
                    content: const Text(
                        'Harap upload kembali dokumen KTP dan foto wajah Anda'),
                    actions: [
                      ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Tidak')),
                      ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const FaceKtp()),
                            );
                          },
                          child: const Text('Ya, Upload Sekarang'))
                    ],
                  ));
          return;
        }

        if (response['state'] == '1') {
          // ignore: use_build_context_synchronously
          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: const Text('Akun Belum Terverifikasi'),
                    content: const Text(
                        'Akun belum terverifikasi, mohon tunggu verifikasi dan akan diinfokan melalui pesan pada nomor yang sudah didaftarkan'),
                    actions: [
                      ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Tutup')),
                    ],
                  ));
          return;
        }

        prefs.setString('username', _usernameController.text);
        prefs.setString('password', _passwordController.text);
        prefs.setString('token', response['token']);
        prefs.setString('_idResgister', id);
        prefs.setString('roleuser', response['roleUser']);

        await Future.delayed(const Duration(seconds: 0));

        if (elapsedTime < 30000) {
          // ignore: use_build_context_synchronously
          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: const Text('IRSMS'),
                    content: const Text(
                        'anda terlalu sering login  tunggu 1 menit !'),
                    actions: [
                      ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Tutup'))
                    ],
                  ));
          return;
        }

        if (!mounted) return;
        postData();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Desktop(id: id)),
          (route) => false,
        );
        loginAttempt = 0;
      } else {
        if (!mounted) return;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        loginAttempt = prefs.getInt('loginAttempt') ?? 0;

        if (elapsedTime < 30000) {
          // ignore: use_build_context_synchronously
          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: const Text('IRSMS'),
                    content: const Text('anda terlalu sering login !'),
                    actions: [
                      ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Tutup'))
                    ],
                  ));
          //return;
        } else {
          // ignore: use_build_context_synchronously
          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: const Text('IRSMS'),
                    content: const Text('Username/password salah !'),
                    actions: [
                      ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Tutup'))
                    ],
                  ));
        }

        loginAttempt++;
      }
      prefs.setInt('loginAttempt', loginAttempt);
      if (loginAttempt >= 2) {
        prefs.setInt('last_login_time', currentTime);
      }
    }
  }

  Future<void> _auth() async {
    if (_connectionStatus == ConnectivityResult.none) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_connectionStatus.toString())));
      return;
    }

    setState(() {
      isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int loginAttempt = prefs.getInt('loginAttempt') ?? 0;
    int lastLoginTime = prefs.getInt('last_login_time') ?? 0;
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    int elapsedTime = currentTime - lastLoginTime;

    var controller = 'masyarakat/login';
    var data = {
      'username': _usernameController.text,
      'password': _passwordController.text
    };

    var response = await RestClient().post(controller: controller, data: data);
    setState(() {
      isLoading = false;
    });

    if (response['status']) {
      String id = response['id'];
      if (response['ktp'] == null || response['selfie'] == null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('_idResgister', id);

        // ignore: use_build_context_synchronously
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('Upload Ulang'),
                  content: const Text(
                      'Anda belum upload foto KTP / Selfie , apakah Anda akan upload sekarang ??'),
                  actions: [
                    ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Tidak')),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const FaceKtp()),
                          );
                        },
                        child: const Text('Ya, Upload Sekarang'))
                  ],
                ));
        return;
      }

      if (response['state'] == '0') {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('_idResgister', id);

        // ignore: use_build_context_synchronously
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('Verifikasi gagal'),
                  content: const Text(
                      'Harap upload kembali dokumen KTP dan foto wajah Anda'),
                  actions: [
                    ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Tidak')),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const FaceKtp()),
                          );
                        },
                        child: const Text('Ya, Upload Sekarang'))
                  ],
                ));
        return;
      }

      if (response['state'] == '1') {
        // ignore: use_build_context_synchronously
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('Akun Belum Terverifikasi'),
                  content: const Text(
                      'Akun belum terverifikasi, mohon tunggu verifikasi dan akan diinfokan melalui pesan pada nomor yang sudah didaftarkan'),
                  actions: [
                    ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Tutup')),
                  ],
                ));
        return;
      }

      prefs.setString('username', _usernameController.text);
      prefs.setString('password', _passwordController.text);
      prefs.setString('token', response['token']);
      prefs.setString('_idResgister', id);

      await Future.delayed(const Duration(seconds: 0));

      if (elapsedTime < 30000) {
        // ignore: use_build_context_synchronously
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('IRSMS'),
                  content:
                      const Text('anda terlalu sering login  tunggu 1 menit !'),
                  actions: [
                    ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Tutup'))
                  ],
                ));
        return;
      }

      if (!mounted) return;
      postData();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Desktop(id: id)),
        (route) => false,
      );
      loginAttempt = 0;
    } else {
      if (!mounted) return;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      loginAttempt = prefs.getInt('loginAttempt') ?? 0;

      if (elapsedTime < 30000) {
        // ignore: use_build_context_synchronously
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('IRSMS'),
                  content: const Text('anda terlalu sering login !'),
                  actions: [
                    ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Tutup'))
                  ],
                ));
        //return;
      } else {
        // ignore: use_build_context_synchronously
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('IRSMS'),
                  content: const Text('Username/password salah !'),
                  actions: [
                    ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Tutup'))
                  ],
                ));
      }

      loginAttempt++;
    }
    prefs.setInt('loginAttempt', loginAttempt);
    if (loginAttempt >= 2) {
      prefs.setInt('last_login_time', currentTime);
    }
  }

  void _registrasi() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const Registrasi()));
  }

  void _lupaPassword() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const VerifikasiAkun()));
  }

  void checkForUpdate() async {
    AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
    print(updateInfo);
    if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
      if (updateInfo.immediateUpdateAllowed) {
        // Untuk pembaruan langsung
        InAppUpdate.performImmediateUpdate().catchError((e) {
          // Tangani error
          print(e);
        });
      } else if (updateInfo.flexibleUpdateAllowed) {
        // Untuk pembaruan fleksibel
        InAppUpdate.startFlexibleUpdate().catchError((e) {
          print(e);
        });
        // Akhiri pembaruan setelah pengunduhan selesai
        InAppUpdate.completeFlexibleUpdate().catchError((e) {
          print(e);
        });
      }
    }
  }

  @override
  void initState() {
    _dialogBuilder;
    _dbhelper = Dbhelper();
    initConnectifity();
    _streamSubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    auth.isDeviceSupported().then((bool isSupported) => setState(
          () => _supportState =
              isSupported ? _SupportState.supported : _SupportState.unsupported,
        ));

    super.initState();
    _initPackageInfo();
    checkForUpdate();
    // var _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    // setState(() {
    //  fetchData();
    //  });
    //  });

    // print(_timer);
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }

  Future<void> _dialogBuilder(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // title: const Text('Basic dialog title'),
          // content: const Text('A dialog is a type of modal window that\n'
          //     'appears in front of app content to\n'
          //     'provide critical information, or prompt\n'
          //     'for a decision to be made.'),
          actions: <Widget>[
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: SliderCaptcha(
                  controller: controller,
                  image: Image.asset(
                    'assets/images/logo-irsms.png',
                    fit: BoxFit.fitWidth,
                  ),
                  colorBar: Colors.blue,
                  colorCaptChar: Colors.blue,
                  //      space: 10,
                  //     fixHeightParent: false,
                  onConfirm: (value) async {
                    if (value.toString() == 'true') {
                      if (_formKey.currentState!.validate() && !isLoading) {
                        //   await _auth();
                        await _cekApi();
                      }
                    } else {
                      print('gagal');
                    }
                    // debugPrint(value.toString());
                    return await Future.delayed(const Duration(seconds: 1))
                        .then(
                      (value) {
                        // print('success');
                        controller.create.call();
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchData() async {
    var controller = 'version/masyarakat';
    var params = {'id': 1};
    var resp = await RestClient().post(controller: controller, data: params);

    setState(() {
      respo = resp['version']; // Mengisi apiResponse dengan data dari API
    });
    // print(resp['version']); // Ganti dengan URL API Anda
    // if (response.statusCode == 200) {
    //   final Map<String, dynamic> responseData = json.decode(response.body);
    //   final String content = responseData['version'];
    //   setState(() {
    //     String dataFromAPI = content;
    //     print(dataFromAPI); // Mengisi dataFromAPI dengan konten dari API
    //   });
    // } else {
    //   throw Exception('Gagal mengambil data dari API');
    // }
  }

  @override
  Widget build(BuildContext context) {
    const String appSubTitles = 'IRSMS PRESISI';
    // const String appSubTitle = '(Masyarakat)';
    final double mediaW = MediaQuery.of(context).size.width;
    final double mediaH = MediaQuery.of(context).size.height;

    final version = _packageInfo.version;
    //   print('testing$version');
    //  var verMasyarakat = respo;
//    print('versin$verMasyarakat');

    Future<String> fetchDatas() async {
      final response = await http.post(Uri.parse(
          'https://irsms.korlantas.polri.go.id/irsmsmobile/version/masyarakat'));
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['version'];
      } else {
        throw Exception('Gagal mengambil data dari API');
      }
    }

    // if (version != verMasyarakat) {
    //   return WillPopScope(
    //     onWillPop: _onWillPop,
    //     child: SafeArea(
    //       child: Scaffold(
    //         body: Container(
    //           width: mediaW,
    //           height: mediaH,
    //           padding: EdgeInsets.symmetric(
    //               horizontal: mediaW > 500 ? mediaW / 4 : 32.0),
    //           decoration: BoxDecoration(
    //               gradient: LinearGradient(
    //                   colors: [my_colors.blue, Colors.blue.shade200],
    //                   begin: Alignment.topCenter,
    //                   end: Alignment.bottomCenter)),
    //           child: Column(
    //             mainAxisAlignment: MainAxisAlignment.center,
    //             children: [
    //               Center(
    //                 child: Image.asset(
    //                   'assets/images/logo-irsms.png',
    //                   width: 0.4 * mediaW,
    //                 ),
    //               ),
    //               const SizedBox(
    //                 height: 16.0,
    //               ),
    //               const AutoSizeText(
    //                 appSubTitles,
    //                 textAlign: TextAlign.center,
    //                 style: TextStyle(
    //                     color: Color.fromARGB(255, 247, 203, 5),
    //                     fontWeight: FontWeight.bold,
    //                     fontSize: 25),
    //               ),
    //               // const AutoSizeText(
    //               //   appSubTitle,
    //               //   textAlign: TextAlign.center,
    //               //   style: TextStyle(
    //               //     color: Color.fromARGB(255, 255, 255, 255),
    //               //     fontWeight: FontWeight.w800,
    //               //   ),
    //               // ),
    //               const SizedBox(
    //                 height: 70.0,
    //               ),
    //               Link(
    //                 uri: Uri.parse(
    //                     'https://play.google.com/store/apps/details?id=id.go.polri.korlantas.irsms.flutter_application_irsms&pcampaignid=web_share'),
    //                 target: LinkTarget.blank,
    //                 builder: (BuildContext ctx, FollowLink? openLink) {
    //                   return Container(
    //                     width: 150, // Lebar kontainer
    //                     height: 40, // Tinggi kontainer
    //                     decoration: BoxDecoration(
    //                       shape: BoxShape
    //                           .rectangle, // Menggunakan bentuk persegi panjang
    //                       borderRadius: BorderRadius.circular(
    //                           50.0), // Mengatur border radius untuk membuatnya menjadi bentuk elips
    //                       color: const Color.fromARGB(255, 243, 166,
    //                           0), // Warna latar belakang kontainer
    //                     ),
    //                     child: TextButton(
    //                       onPressed: openLink,
    //                       child: const Text(
    //                         'Update !',
    //                         textAlign: TextAlign.center,
    //                         style: TextStyle(
    //                           color: Colors.white, // Warna teks
    //                           fontSize: 15.0,
    //                           fontWeight: FontWeight.bold, // Ukuran teks
    //                         ),
    //                       ),
    //                     ),
    //                   );
    //                   // TextButton.icon(
    //                   //   onPressed: openLink,
    //                   //   label: const Text(
    //                   //     textAlign: TextAlign.center,
    //                   //     style: TextStyle(
    //                   //       color: Color.fromARGB(255, 247, 203, 5),
    //                   //       fontWeight: FontWeight.bold,
    //                   //       //  fontSize: 25,
    //                   //     ),
    //                   //     'UPDATE VERSI TERBARU !',
    //                   //   ),
    //                   //   icon: const Icon(Icons.download),
    //                   // );
    //                 },
    //               ),
    //             ],
    //           ),
    //         ),
    //       ),
    //     ),
    //   );
    // } else {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
          child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            width: mediaW,
            height: mediaH,
            padding: EdgeInsets.symmetric(
                horizontal: mediaW > 500 ? mediaW / 4 : 32.0),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [my_colors.blue, Colors.blue.shade200],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter)),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Center(
                child: Image.asset(
                  'assets/images/logo-irsms.png',
                  width: 0.4 * mediaW,
                ),
              ),
              const SizedBox(
                height: 16.0,
              ),
              const AutoSizeText(
                appSubTitles,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color.fromARGB(255, 247, 203, 5),
                    fontWeight: FontWeight.bold,
                    fontSize: 25),
              ),
              // const AutoSizeText(
              //   appSubTitle,
              //   textAlign: TextAlign.center,
              //   style: TextStyle(
              //     color: Color.fromARGB(255, 255, 255, 255),
              //     fontWeight: FontWeight.w800,
              //   ),
              // ),
              // const SizedBox(
              //   height: 48.0,
              // ),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Nama Pengguna',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          color: my_colors.blue, fontWeight: FontWeight.bold),
                    ),
                    TextFormField(
                      key: const Key('username'),
                      controller: _usernameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.only(
                            top: 0, right: 30, bottom: 0, left: 15),
                        hintText: 'Ketik Nama Penguna di Sini',
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '* wajib diisi';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 8.0,
                    ),
                    const Text(
                      'Kata Sandi',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          color: my_colors.blue, fontWeight: FontWeight.bold),
                    ),
                    TextFormField(
                      key: const Key('password'),
                      controller: _passwordController,
                      obscureText: showPassword ? false : true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Ketik Kata Sandi di Sini',
                        contentPadding: const EdgeInsets.only(
                            top: 0, right: 30, bottom: 0, left: 15),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              showPassword = !showPassword;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10, right: 15),
                            child: Icon(
                              showPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: my_colors.blue,
                              size: 20,
                            ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _lupaPassword,
                          child: const Text(
                            'Lupa Password?',
                            textAlign: TextAlign.right,
                            style:
                                TextStyle(color: my_colors.blue, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    //const SizedBox(height: 5.0),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              // await _dialogBuilder(context);
                              //  await _cekApi();
                              if (_formKey.currentState!.validate() &&
                                  !isLoading) {
                                await _dialogBuilder(context);
                              }
                            },
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all(my_colors.yellow),
                              padding: MaterialStateProperty.all(
                                  const EdgeInsets.all(16)),
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                            ),
                            child: (isLoading)
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Theme.of(context).primaryColor,
                                      strokeWidth: 1.5,
                                    ),
                                  )
                                : Text(
                                    'Masuk',
                                    style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(
                          width: 8.0,
                        ),
                        // ElevatedButton(
                        //   onPressed: () async {
                        //     FocusManager.instance.primaryFocus?.unfocus();

                        //     var whatsappUrl = "https://wa.me/$_noHP";
                        //     try {
                        //       launch(whatsappUrl);
                        //     } catch (e) {
                        //       //To handle error and display error message
                        //       // Helper.errorSnackBar(
                        //       //     context: context,
                        //       //     message: "Unable to open whatsapp");
                        //     }
                        //   },
                        //   style: ButtonStyle(
                        //       backgroundColor:
                        //           MaterialStateProperty.all(my_colors.yellow),
                        //       padding: MaterialStateProperty.all(
                        //           const EdgeInsets.all(15))),
                        //   child: Image.asset(
                        //     'assets/images/whatsapp.png', // Ganti dengan nama file gambar WhatsApp Anda
                        //     width: 25,
                        //     height: 25,
                        //   ),
                        // ),
                        const SizedBox(
                          height: 8.0,
                        ),
                        TextButton(
                          onPressed: () async {
                            await _authenticate(
                                biometricOnly:
                                    _supportState != _SupportState.supported);

                            if (_authorized == 'Authorized') {
                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();

                              setState(() {
                                _usernameController.text =
                                    prefs.getString('username')!;
                                _passwordController.text =
                                    prefs.getString('password')!;
                              });

                              await _cekApi();
                            }
                          },
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(my_colors.yellow),
                            padding: MaterialStateProperty.all(
                              const EdgeInsets.all(16),
                            ),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                          ),
                          child: Builder(builder: (context) {
                            if (_supportState == _SupportState.unknown) {
                              return const CircularProgressIndicator();
                            } else if (_supportState ==
                                _SupportState.unsupported) {
                              return const Icon(
                                Icons.lock,
                                color: my_colors.blue,
                              );
                            }

                            return const Icon(
                              Icons.fingerprint,
                              color: my_colors.blue,
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 8.0,
              ),
              Center(
                  child: RichText(
                      text: TextSpan(children: [
                const TextSpan(
                  text: 'Belum punya akun?',
                  style: TextStyle(color: my_colors.blue, fontSize: 13),
                ),
                TextSpan(
                    text: ' Daftar sekarang',
                    style: const TextStyle(
                        color: my_colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                    recognizer: TapGestureRecognizer()..onTap = _registrasi)
              ]))),
              const SizedBox(
                height: 64.0,
              ),
              //  const SizedBox(height: 350.0),
              Center(
                child: InkWell(
                  onTap: () async {},
                  child: Text(
                    'versi $version',
                    style: const TextStyle(fontSize: 10.0, color: Colors.white
                        //  decoration: TextDecoration.underline,
                        ),
                  ),
                ),
              )
            ]),
          ),
        ),
      )),
    );
    //   }
  }

  Future<void> initConnectifity() async {
    late ConnectivityResult result;

    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
      return;
    }

    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
    });
  }

  // Future<void> _checkBiometrics() async {
  //   late bool canCheckBiometrics;
  //   try {
  //     canCheckBiometrics = await auth.canCheckBiometrics;
  //   } on PlatformException catch (e) {
  //     canCheckBiometrics = false;
  //   }

  //   if (!mounted) {
  //     return;
  //   }

  //   setState(() {
  //     _canCheckBiometrics = canCheckBiometrics;
  //   });
  // }

  // Future<void> _getAvailableBiometrics() async {
  //   late List<BiometricType> availableBiometrics;
  //   try {
  //     availableBiometrics = await auth.getAvailableBiometrics();
  //   } on PlatformException catch (e) {
  //     availableBiometrics = <BiometricType>[];
  //     print(e);
  //   }

  //   if (!mounted) {
  //     return;
  //   }

  //   setState(() {
  //     _availableBiometrics = availableBiometrics;
  //   });
  // }

  Future<void> _authenticate({bool biometricOnly = true}) async {
    bool authenticated = false;
    try {
      setState(() {
        // _isAuthenticating = true;
        _authorized = 'Authenticating';
      });

      authenticated = await auth.authenticate(
          localizedReason: 'Please authenticate yourself',
          options: AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: biometricOnly,
              useErrorDialogs: true));

      setState(() {
        // _isAuthenticating = false;
        _authorized = 'Authenticating';
      });
    } on PlatformException catch (e) {
      setState(() {
        // _isAuthenticating = false;
        _authorized = 'Error - ${e.message}';
      });

      return;
    }

    if (!mounted) {
      return;
    }

    setState(
      () => _authorized = authenticated ? 'Authorized' : 'Not Authorized',
    );
  }

  // Future<void> _cancelAuthentication() async {
  //   await auth.stopAuthentication();
  //   setState(
  //     () => _isAuthenticating = false,
  //   );
  // }
}

enum _SupportState {
  unknown,
  supported,
  unsupported,
}
