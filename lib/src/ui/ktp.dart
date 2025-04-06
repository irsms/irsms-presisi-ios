import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_application_irsms/src/ui/face_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../libraries/colors.dart' as my_colors;
import '../services/rest_client.dart';

import 'card_picture_auth.dart';

class FaceKtp extends StatefulWidget {
  const FaceKtp({super.key});

  @override
  State<FaceKtp> createState() => _FaceKtpState();
}

class _FaceKtpState extends State<FaceKtp> {
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;
  final ImagePicker picker = ImagePicker();
  File? imageKtp;
  File? image;
  String? imagePaths;
  late String stringValue;

  Future<String?> _captureKtpImage() async {
    XFile? xFileKtp = await picker.pickImage(
        source: ImageSource.camera, maxWidth: 1200, maxHeight: 1200);

    if (xFileKtp != null) {
      image = File(xFileKtp.path);

      String? imageKtp = image?.path;
      // Konversi gambar ke string base64
      List<int> imageBytes = await image!.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Simpan string base64 ke SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('ktpImageBase64', base64Image);

      setState(() {});

      return imageKtp;
    }
    return null;
  }

  Future<void> _submit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? base64Image = prefs.getString('ktpImageBase64');

    // Validasi apakah base64Image tersedia
    if (base64Image == null || base64Image.isEmpty) {
      // Tampilkan pop-up peringatan
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Peringatan'),
            content: const Text(
                'Foto KTP belum tersedia. Silakan ambil foto KTP terlebih dahulu.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return; // Hentikan eksekusi jika validasi gagal
    }

    // Jika validasi berhasil, lanjutkan ke halaman FaceAuth
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FaceAuth()),
    );
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => FaceAuth()),
    // );
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // stringValue = prefs.getString('_idResgister') ?? '';

    // //   print(stringValue);
    // var stringValue2 = stringValue;
    // var respPersonKtp = await RestClient()
    //     .uploadPhotoRegisterKtp(path: image!.path, id: stringValue);
    // // print(respPersonKtp);
    // if (respPersonKtp['status'] == true) {
    //   //  Navigator.pushNamed(context, '/face');
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(builder: (context) => FaceAuth()),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Verifikasi KTP'),
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
              height: 30.0,
            ),
            Center(
              child: CardPictureAuth(
                  onTap: _captureKtpImage, imagePath: image?.path
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
              height: 15.0,
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
                    'lanjutkan',
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
