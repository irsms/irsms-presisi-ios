import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_irsms/main.dart';
import 'package:flutter_application_irsms/src/ui/card_picture_selfie.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../libraries/colors.dart' as my_colors;
import '../services/rest_client.dart';
import 'card_picture_auth.dart';

class FaceAuth extends StatefulWidget {
  const FaceAuth({super.key});

  @override
  State<FaceAuth> createState() => _FaceAuthState();
}

class _FaceAuthState extends State<FaceAuth> {
  final ImagePicker picker = ImagePicker();
  File? imageKtp;
  File? image;
  String? imagePaths;
  late String stringValue;
  bool isLoading = false;
  RestClient restClient = RestClient();

  Future<String?> _captureSelfieImage() async {
    XFile? xFileSelfie = await picker.pickImage(
        source: ImageSource.camera, maxWidth: 1200, maxHeight: 1200);

    if (xFileSelfie != null) {
      image = File(xFileSelfie.path);

      String? imageSelfie = image?.path;

      setState(() {});

      return imageSelfie;
    }
    return null;
  }

  Future<void> _submit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? jsonData = prefs.getString('userData');
    await prefs.remove('_idResgister');
    print(jsonData);
    String? base64Image = prefs.getString('ktpImageBase64');
    if (jsonData != null) {
      Map<String, dynamic> data = jsonDecode(jsonData);
      var controller = 'masyarakat/registrasiTest';
      var resp = await restClient.post(controller: controller, data: data);
      String cekId = resp['id'].toString();

      prefs.setString('_idResgister', cekId);
      if (resp['status']) {
        await Future.delayed(const Duration(seconds: 3));
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });
      } else {
        if (!mounted) return;

        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('IRSMS'),
                  content: Text(resp['error']),
                  actions: [
                    TextButton(
                        onPressed: () {
                          setState(() {
                            isLoading = false;
                          });
                          Navigator.of(context).pop();
                        },
                        child: const Text('Tutup'))
                  ],
                ));
      }
    }
    stringValue = prefs.getString('_idResgister') ?? '';
    if (base64Image != null) {
      Uint8List imageBytes = base64Decode(base64Image);
      var respPersonKtp = await RestClient()
          .uploadPhotoRegisterKtp(path: image!.path, id: stringValue);
      // Gunakan `imageBytes` sesuai kebutuhan, seperti untuk menampilkan gambar menggunakan Image.memory()
    }

    var respPersonKtp = await RestClient()
        .uploadPhotoRegisterSelfie(path: image!.path, id: stringValue);

    if (respPersonKtp['status'] == true) {
      Map<String, dynamic> data = {
        "state": "1",
      };

      var controller = 'masyarakat/updateRegistrasiMasyarakat';
      var params = {
        'masyarakat__members_id': stringValue,
      };
      await RestClient()
          .put(controller: controller, params: params, data: data);

      // ignore: use_build_context_synchronously
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('IRSMS MASYARAKAT'),
                content: const Text(
                    'akun berhasil di daftarkan silahkan tunggu verifikasi, dan setelah verifikasi anda dapat login dengan username & password yang telah anda buat'),
                actions: [
                  TextButton(
                      onPressed: () {
                        setState(() {
                          isLoading = false;
                        });
                        // Navigator.of(context).pop();
                        //    Navigator.pushNamed(context, '/');
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MyHomePage(
                                    title: 'IRSMS',
                                  )),
                        );
                      },
                      child: const Text('Tutup'))
                ],
              ));
      //  Navigator.pushNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Akun'),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // if (imageKtp != null)
            //   Image.file(
            //     imageKtp!,
            //     height: 200,
            //   ),
            // ElevatedButton(
            //   onPressed: _captureKtpImage,
            //   child: const Text('Ambil Foto'),
            // ),
            // ElevatedButton(
            //   onPressed: (){
            //     _submit(imageKtp);,
            //   },child: const Text('Submit'),
            // ),
            const SizedBox(
              height: 20.0,
            ),
            Center(
              child: CardPictureSelfie(
                  onTap: _captureSelfieImage, imagePath: image?.path
                  // () async {
                  // XFile? xFile = await picker.pickImage(
                  //     source: ImageSource.camera,
                  //     maxWidth: 100,
                  //     maxHeight: 100);

                  // if (xFile != null) {
                  //   image = File(xFile.path);
                  //   imagePaths.add(image!.path);

                  //   setState(() {});
                  // }
                  // },
                  // imagePath: image?.path
                  ),
            ),
            const SizedBox(
              height: 20.0,
            ),
            SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 60.0,
                child: ElevatedButton(
                  onPressed: () {
                    _submit();
                  },
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(my_colors.yellow),
                    padding:
                        MaterialStateProperty.all(const EdgeInsets.all(16)),
                  ),
                  child: Text(
                    'Selesaikan !',
                    style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
