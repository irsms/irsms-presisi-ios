import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_irsms/src/ui/lapor_laka_petugas.dart';
import 'package:flutter_application_irsms/src/ui/pengaduan_petugas.dart';
import 'package:flutter_application_irsms/src/ui/profil_petugas.dart';
import 'package:flutter_application_irsms/src/ui/peta_ios.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../libraries/colors.dart' as my_colors;
import '../services/rest_client.dart';
import 'daftar_laka.dart';
import 'blackspot.dart';
// import 'peta.dart';
import 'slideshow.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message ${message.messageId}');
}

/// Create a [AndroidNotificationChannel] for heads up notifications
AndroidNotificationChannel? channel;

bool isFlutterLocalNotificationsInitialized = false;

/// Initialize the [FlutterLocalNotificationsPlugin] package.
FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

class Desktop_petugas extends StatefulWidget {
  final id;
  const Desktop_petugas({super.key, this.id});

  @override
  State<Desktop_petugas> createState() => _DesktopState();
}

class _DesktopState extends State<Desktop_petugas> {
  static final List<String> _slides = [];

  // Future<void> _getWill() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String token = prefs.getString('token') ?? '';
  //   var controllers = 'masyarakat/aduan';
  //   var param = {'token': token};
  //   Map<String, dynamic> profile =
  //       await RestClient().get(controller: 'petugas/profile', params: {
  //     'token': token,
  //   });
  //   var _getWilayah = profile['rows'][0]['polres_id'];
  //   //  print(_getWilayah);
  //   if (profile['status']) {
  //     if (profile['polres_id'] != null) {
  //       var wilayah = await RestClient().get(
  //           controller: 'ref_wilayah',
  //           params: {"token": token, "polres_id": profile['polres_id']});

  //       if (wilayah['status']) {
  //         param['satuan_kepolisian'] = wilayah['rows'][0]['nama_dati'];
  //       }
  //     }
  //   }
  // }
  Future<void> _getWill() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    var controllers = 'masyarakat/aduan';
    var param = {'token': token};
    Map<String, dynamic> profile =
        await RestClient().get(controller: 'petugas/profile', params: {
      'token': token,
    });
    print(profile);
    var getWilayah = profile['rows'][0]['polres_id'];
    //  print(_getWilayah);
    if (profile['status']) {
      if (profile['polres_id'] != null) {
        var wilayah = await RestClient().get(
            controller: 'ref_wilayah',
            params: {"token": token, "polres_id": profile['polres_id']});

        if (wilayah['status']) {
          param['satuan_kepolisian'] = wilayah['rows'][0]['nama_dati'];
        }
      }

      // for (var i = 0; i < _isSelected.length; i++) {
      //   if (_isSelected[i][0]) {
      //     params['category[$i]'] = _categories[i];
      //   }
      // }

      // Map<String, dynamic> res =
      //     await RestClient().get(controller: controllers, params: param);

      //  print(res['rows'][0]['satuan_kepolisian']);

      //  print(_getWilayah);
      // await FirebaseMessaging.instance.subscribeToTopic(_getWilayah);
      // await FirebaseMessaging.instance.subscribeToTopic('berita');
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
                        onPressed: () => Navigator.pushNamed(context, '/'),
                        child: const Text('Ya')),
                  ],
                ))) ??
        false;
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      String token = prefs.getString('token') ?? '';
      await _getWill();
      setState(() {});
      var controller = 'masyarakat/slides';
      var params = {'token': token};
      Map<String, dynamic> resp =
          await RestClient().get(controller: controller, params: params);

      if (resp['status']) {
        setState(() {
          List<String> buffers = [];
          resp['rows'].forEach((slide) {
            String element = '${RestClient().baseURL}/${slide['slide']}';
            buffers.add(element);
          });

          if (listEquals(_slides, buffers) == false) {
            _slides.clear();
            for (var element in buffers) {
              if (!_slides.contains(element)) {
                _slides.add(element);
              }
            }
          }
        });
      } else if (mounted) {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('IRSMS'),
                  content: Text(resp['error'].toString()),
                  actions: [
                    TextButton(
                        onPressed: () {
                          if (resp['error'].toString() == 'Expired token') {
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
    final double mainContainerHeight = MediaQuery.of(context).size.height -
        kToolbarHeight -
        kBottomNavigationBarHeight;

    final double sliderContainerHeight = 0.5 * mainContainerHeight;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Beranda IRSMS'),
            InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: ((context) => const ProfilPetugas())));
              },
              child: Container(
                  width: kToolbarHeight - 16,
                  height: kToolbarHeight - 16,
                  decoration: BoxDecoration(
                      color: my_colors.yellow,
                      borderRadius: BorderRadius.circular(kToolbarHeight - 16)),
                  child: const Icon(
                    Icons.person,
                    color: my_colors.blue,
                  )),
            )
          ],
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/pataka.png'),
              repeat: ImageRepeat.repeat,
              scale: 4),
        ),
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(color: Colors.white.withAlpha(192)),
          child: SingleChildScrollView(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: sliderContainerHeight,
                  child: _slides.isNotEmpty
                      ? SlideshowWidget(
                          slides: _slides,
                          height: sliderContainerHeight,
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
              SizedBox(
                // height: mainContainerHeight - sliderContainerHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShortcutWidget(shortcut: shortcut[0]),
                        ShortcutWidget(shortcut: shortcut[1]),
                        ShortcutWidget(shortcut: shortcut[2]),
                        // ShortcutWidget(shortcut: shortcut[3]),
                      ],
                    ),
                    const SizedBox(
                      height: 50,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShortcutWidget(
                            shortcut: Shortcut(
                          name: 'Laporan Masyarakat',
                          icon: Icons.group_add,
                          builder: (context) => const PengaduanPetugas(),
                        )),
                        ShortcutWidget(
                            shortcut: Shortcut(
                          name: 'Black Spot',
                          icon: Icons.group_add,
                          builder: (context) => const Blackspot(),
                        )),
                      ],
                    ),
                  ],
                ),
              )
            ]),
          ),
        ),
        //   ),
      ),
    );
  }
}

class SlideWidget extends StatelessWidget {
  final String image;

  const SlideWidget({required this.image, super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(image, fit: BoxFit.fitHeight);
  }
}

class ShortcutWidget extends StatelessWidget {
  final Shortcut? shortcut;

  const ShortcutWidget({this.shortcut, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
        // mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(
              // width: 128,
              // height: 128,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context, MaterialPageRoute(builder: shortcut!.builder));
                },
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(my_colors.yellow),
                    padding:
                        MaterialStateProperty.all(const EdgeInsets.all(15)),
                    shape: MaterialStateProperty.all(const CircleBorder())),
                child: Icon(
                  shortcut!.icon,
                  color: my_colors.blue,
                  size: 0.125 * MediaQuery.of(context).size.width - 16,
                ),
              )),
          const SizedBox(
            height: 16,
          ),
          SizedBox(
              // width: 96,
              // height: 50,
              child: Text(
            shortcut!.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
                color: my_colors.blue, fontWeight: FontWeight.w900),
          ))
        ]);
  }
}

class Shortcut {
  final String name;
  final IconData icon;
  final WidgetBuilder builder;

  const Shortcut(
      {required this.name, required this.icon, required this.builder});
}

final shortcut = [
  Shortcut(
    name: 'Daftar Laka',
    icon: Icons.add_box,
    builder: (context) => const DaftarLaka(
      imageUrls: [],
    ),
  ),
  Shortcut(
    name: 'Peta',
    icon: Icons.map_outlined,
    builder: (context) => const PetaIos(),
    // builder: (context) => const LaporLakaPetugas(),
  ),
  Shortcut(
    name: 'Lapor Laka',
    icon: Icons.add_to_photos_outlined,
    builder: (context) => const LaporLakaPetugas(),
  ),
  Shortcut(
    name: 'Laporan Masyarakat',
    icon: Icons.group_add,
    builder: (context) => const PengaduanPetugas(),
  ),
  Shortcut(
    name: 'Black Spot',
    icon: Icons.group_add,
    builder: (context) => const Blackspot(),
  ),
];
