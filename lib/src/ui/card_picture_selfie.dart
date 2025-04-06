import 'dart:io';
import 'package:flutter/material.dart';
import '../libraries/colors.dart' as my_colors;

class CardPictureSelfie extends StatelessWidget {
  const CardPictureSelfie({this.onTap, this.imagePath, super.key});

  final Function()? onTap;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (imagePath != null) {
      return Card(
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Verifikasi Data',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: my_colors.blue),
                ),
                Center(
                    child: (imagePath == null
                        ? Text(
                            'Ambil gambar Selfie',
                            style: TextStyle(
                                fontSize: 17, color: Colors.grey[600]),
                          )
                        : Container(
                            width: MediaQuery.of(context).size.width * 0.9,
                            height: MediaQuery.of(context).size.height * 0.6,
                            decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(4.0)),
                              image: DecorationImage(
                                  fit: BoxFit.fitHeight,
                                  image: FileImage(File(imagePath as String))),
                            ),
                          ))),
                // Icon(
                //   Icons.photo_camera,
                //   color: Colors.indigo[400],
                // )
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 5,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt,
                color: Colors.indigo[800],
                size: 200.0,
              ),
              Text(
                'Klik icon !',
                style: TextStyle(fontSize: 17.0, color: Colors.grey[600]),
              ),
              Text(
                'Ambil Foto Selfie',
                style: TextStyle(fontSize: 17.0, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
