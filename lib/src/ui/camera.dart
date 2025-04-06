import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_application_irsms/src/ui/tambah_data.dart';
// import 'package:geocoding/geocoding.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';

class OpenCamera extends StatefulWidget {
  //const OpenCamera({super.key, Key? key});

  @override
  State<OpenCamera> createState() => _OpenCameraState();
}

class _OpenCameraState extends State<OpenCamera> {
  late CameraController _controller;
  Location location = Location();
  bool _isInited = false;
  bool _isLoading = false;
  final List<String?> _imageUrls = List.filled(3, null);
  final String _accidentUuid = const Uuid().v1();
  int _nextPreviewIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.high);
    await _controller.initialize();
    _addWatermark((await getTemporaryDirectory()).path);

    setState(() {
      _isInited = true;
    });
  }

  // Future<String> _getStreetName(double latitude, double longitude) async {
  //   List<Placemark> placemarks =
  //       await placemarkFromCoordinates(latitude, longitude);
  //   Placemark place = placemarks[0];
  //   return place.street ?? 'Unknown';
  // }

  Future<File> _addWatermark(String imagePath) async {
    final DateTime now = DateTime.now();
    final String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    final File imageFile = File(imagePath);

    // Read the image
    final img.Image? image = img.decodeImage(imageFile.readAsBytesSync());

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Add watermark text
    final img.Image finalImage = img.copyResize(image, width: 800, height: 600);
    img.drawString(finalImage, img.arial_24, 10, 10, formattedDate);

    // Save the image with watermark
    final File newImageFile = File(
        '${imageFile.parent.path}/${now.millisecondsSinceEpoch}_watermarked.png');
    newImageFile.writeAsBytesSync(img.encodePng(finalImage));

    return newImageFile;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Camera"),
      ),
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: _isInited
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: CameraPreview(_controller),
                    )
                  : const Center(
                      child: CircularProgressIndicator(),
                    ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: MediaQuery.of(context).size.width * 0.3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (int i = 0; i < 3; i++)
                    GestureDetector(
                      child: Container(
                        foregroundDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0)),
                        height: double.infinity,
                        width: MediaQuery.of(context).size.width / 3 - 16,
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _nextPreviewIndex == i
                                ? const Color.fromARGB(255, 3, 18, 136)
                                : Colors.grey,
                          ),
                        ),
                        // child: _imageUrls[i] != null
                        //     ? Image.file(
                        //         File(_imageUrls[i]!),
                        //         fit: BoxFit.cover,
                        //       )
                        //     : _isLoading
                        //         ? Center(
                        //             child: CircularProgressIndicator(),
                        //           )
                        //         : Center(
                        //             child: Text("Foto ${i + 1}"),
                        //           ),
                        child: SizedBox(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_imageUrls[i] != null)
                                Image.file(
                                  File(_imageUrls[i]!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              if (_imageUrls[i] == null &&
                                  _isLoading &&
                                  _nextPreviewIndex == i)
                                const CircularProgressIndicator(),
                              if (_imageUrls[i] == null && !_isLoading)
                                Center(
                                  child: Text("Foto ${i + 1}"),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(
              height: 16,
            )
          ],
        ),
      ),
      floatingActionButton: _nextPreviewIndex < 3
          ? FloatingActionButton(
              backgroundColor: const Color.fromARGB(255, 3, 18, 136),
              child: const Icon(Icons.camera_alt_outlined),
              onPressed: () async {
                setState(() {
                  _isLoading = true; // Menampilkan indikator loading
                });
                final path = join((await getTemporaryDirectory()).path,
                    '${DateTime.now().millisecondsSinceEpoch}_$_nextPreviewIndex.png');
                try {
                  XFile picture = await _controller.takePicture();
                  final String imagePath = picture.path;
                  final File imageFile = File(imagePath);

                  img.Image? image =
                      img.decodeImage(imageFile.readAsBytesSync());
                  final shortestSide = MediaQuery.of(context).size.shortestSide;
                  print(shortestSide);
                  if (shortestSide > 399) {
                    image = img.copyRotate(image!, 90);
                  } else {
                    image = img.copyRotate(image!, 0);
                  }
                  DateTime now = DateTime.now();
                  String timestamp =
                      "${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}:${now.second}";
                  Location locationn = Location();
                  var position = await locationn.getLocation();

                  // Position position = await Geolocator.getCurrentPosition(
                  //   desiredAccuracy: LocationAccuracy.high,
                  // );
                  String location =
                      "${position.latitude}, ${position.longitude}";

                  ///         Dapatkan alamat dari koordinat
                  //     List<Placemark> placemarks = await placemarkFromCoordinates(
                  // position.latitude,
                  // position.longitude,
                  //    );
                  //     String address = placemarks[0].street!;

                  // Tambahkan watermark dari waktu diambil
                  img.drawString(
                    image,
                    img.arial_14, // Font
                    10, // Koordinat X
                    image.height - 150, // Koordinat Y
                    timestamp, // Teks watermark
                    color: img.getColor(
                        255, 255, 255), // Warna teks (putih dalam RGB)
                    // thickness: 2, // Ketebalan teks
                  );

                  img.drawString(
                    image,
                    img.arial_14, // Font
                    10, // Koordinat X
                    image.height - 135, // Koordinat Y untuk lokasi
                    location, // Teks watermark lokasi
                    color: img.getColor(
                        255, 255, 255), // Warna teks (putih dalam RGB)
                    //      thickness: 2, // Ketebalan teks
                  );

                  // img.drawString(
                  //   image,
                  //   img.arial_14, // Font
                  //   10, // Koordinat X
                  //   image.height - 120, // Koordinat Y untuk lokasi
                  //   address, // Teks watermark lokasi
                  //   color: img.getColor(255, 255, 255),
                  //   // Warna teks (putih dalam RGB)
                  //   //      thickness: 2, // Ketebalan teks
                  // );

// Menambahkan teks watermark ke gambar
                  //  img.drawString(image, img.arial_14, 10, 80, watermarkText);
                  imageFile.writeAsBytesSync(img.encodePng(image));

// Menyimpan path gambar dengan watermark ke dalam _imageUrls
                  setState(() {
                    _imageUrls[_nextPreviewIndex] = imagePath;
                    _nextPreviewIndex++;
                    _isLoading = false;
                  });
                } catch (e) {
                  print('Error saat mengambil gambar: $e');
                }
              },
            )
          : FloatingActionButton.extended(
              backgroundColor: const Color.fromARGB(255, 3, 18, 136),
              icon: const Icon(Icons.arrow_forward),
              label: const Text("Lanjutkan !"),
              onPressed: () {
                _controller.dispose();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TambahData(
                          accidentUuid: _accidentUuid, imageUrls: _imageUrls)),
                );
              },
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
