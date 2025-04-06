import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../libraries/colors.dart' as my_colors;
import '../services/rest_client.dart';
import 'card_picture.dart';
import 'pengaduan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FormAduan extends StatefulWidget {
  const FormAduan({super.key});

  @override
  State<FormAduan> createState() => _FormAduanState();
}

class _FormAduanState extends State<FormAduan> {
  final _formKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();
  File? _image;

  bool isLoading = false;

  String _token = '';
  String? _currentAddress;
  String? _currentRoadname;
  Position? _currentPosition;

  Map<String, dynamic> _wilayah = {};

  List<String> get _imagePaths => [_image!.path];

  final TextEditingController _roadNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _satuanKepolisianController =
      TextEditingController();

  var kategoriLaporan = ['Kemacetan', 'Jalan Rusak', 'Rawan Laka'];

  String? selectedKategoriLaporan;
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() => _currentPosition = position);
      _getAddressFromLatLng(_currentPosition!);
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
            _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      print(place);
      setState(() {
        _currentAddress =
            '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}';
        _currentRoadname = '${place.subAdministrativeArea}';
      });
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<void> _submit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    setState(() {
      isLoading = true;
    });

    var profile =
        await RestClient().get(controller: 'masyarakat/profile', params: {
      'token': _token,
    });

    if (profile['status']) {
      var resp = await RestClient().uploadPhotos(_imagePaths);
      print(resp);

      if (resp.containsKey('status')) {
        if (resp['status']) {
          String fullPath = resp['rows'][0]['full_path'];

          Map<String, dynamic> data = {
            'picture': fullPath,
            'road_name': _currentAddress,
            'satuan_kepolisian': _satuanKepolisianController.text,
            'category': selectedKategoriLaporan,
            'description': _descriptionController.text,
            'latitude': _currentPosition?.latitude,
            'longitude': _currentPosition?.longitude,
            'created_at': DateFormat('yyyy-MM-dd').format(DateTime.now()),
            'masyarakat__members_id': profile['rows'][0]
                ['masyarakat__members_id']
          };

          String controller = 'masyarakat/aduan';

          var postResp = await RestClient()
              .post(token: _token, controller: controller, data: data);

          if (postResp['status']) {
            setState(() {
              isLoading = false;
            });

            final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
            var controller = 'ref_wilayah/polres_id';
            var params = {
              'token': token,
              'nama_dati': _satuanKepolisianController.text
            };

            // print(params);

            var resp =
                await RestClient().get(controller: controller, params: params);
            final getWilayah = resp['data'][0]['polres_id'];

            // Define the data to be sent as a JSON object
            final data = {
              "to": "/topics/$getWilayah",
              "notification": {
                "title": "Laporan Pengduan Masyarakat",
                "body": "$selectedKategoriLaporan  di jalan $_currentAddress",
                "icon": "icon.png",
                "image": fullPath
              },
              "data": {"key1": "value1", "key2": "value2"}
            };
            final jsonData = jsonEncode(data);
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

            await Future.delayed(const Duration(seconds: 3));
            if (!mounted) return;
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Pengaduan()));
          } else {
            if (!mounted) return;

            showDialog(
                context: context,
                builder: (context) => AlertDialog(
                      title: const Text('IRSMS'),
                      content: Text(postResp['error']),
                      actions: [
                        TextButton(
                            onPressed: () {
                              setState(() {
                                isLoading = false;
                              });

                              if (postResp['error'] == 'Expired token') {
                                Navigator.pushNamed(context, '/');
                              } else {
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text('Tutup'))
                      ],
                    ));
          }
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
      } else {
        if (resp.containsKey('message')) {
          if (!mounted) return;

          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: const Text('IRSMS'),
                    content: Text(resp['message']),
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
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _getCurrentPosition();
      _token = prefs.getString('token') ?? '';

      var controller = 'masyarakat/ref_wilayah';
      var params = {'token': _token};
      _wilayah = await RestClient().get(controller: controller, params: params);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Form Aduan'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: CardPicture(
                    onTap: () async {
                      XFile? xFile = await _picker.pickImage(
                          source: ImageSource.camera,
                          maxWidth: 300,
                          maxHeight: 300);

                      if (xFile != null) {
                        _image = File(xFile.path);
                        _imagePaths.add(_image!.path);

                        setState(() {});
                      }
                    },
                    imagePath: _image?.path,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                const Text(
                  'Nama Jalan',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: my_colors.blue, fontWeight: FontWeight.bold),
                ),
                Container(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      controller: TextEditingController(
                          text: (_currentAddress ?? "").toUpperCase()),
                      enabled: false,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.only(
                            top: 0, right: 30, bottom: 0, left: 16),
                        hintText: _currentAddress ?? "",
                      ),
                      autovalidateMode: AutovalidateMode.always,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '* wajib diisi';
                        }
                        if (value.contains(RegExp(r'[!@#%^&*()?"/;:{}|<>]'))) {
                          return 'Teks tidak boleh mengandung simbol!';
                        }

                        return null;
                      },
                    )),
                const Text(
                  'Wilayah',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: my_colors.blue, fontWeight: FontWeight.bold),
                ),
                TypeAheadFormField(
                  textFieldConfiguration: TextFieldConfiguration(
                    controller: _satuanKepolisianController,
                    //  enabled: false,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.only(
                          top: 0, right: 30, bottom: 0, left: 16),
                      hintText: 'isi wilayah disini',
                    ),
                  ),
                  onSuggestionSelected: ((suggestion) {
                    _satuanKepolisianController.text = suggestion.toString();
                  }),
                  itemBuilder: ((context, itemData) {
                    return ListTile(
                      title: Text(itemData.toString()),
                    );
                  }),
                  suggestionsCallback: (pattern) {
                    List<String> wilayah = [];
                    if (pattern.length > 2) {
                      _wilayah['rows'].forEach((item) {
                        if (RegExp(pattern).hasMatch(item['nama_dati'])) {
                          wilayah.add(item['nama_dati']);
                        }
                      });
                    }

                    return wilayah;
                  },
                  autovalidateMode: AutovalidateMode.always,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '* wajib diisi';
                    }
                    if (value.contains(RegExp(r'[!@#%^&*()?"/;:{}|<>]'))) {
                      return 'Teks tidak boleh mengandung simbol!';
                    }

                    return null;
                  },
                ),
                const SizedBox(
                  height: 16,
                ),
                const Text(
                  'Kategori Laporan',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: my_colors.blue, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.only(left: 16, right: 10),  // Mengatur padding button
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    isExpanded: true,
                    hint: const Text('Pilih Kategori Laporan'),
                    icon: const Icon(Icons.keyboard_arrow_down),
                    iconSize: 30,
                    items: kategoriLaporan
                        .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                        .toList(),
                    autovalidateMode: AutovalidateMode.always,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Silahkan pilih kategori';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      selectedKategoriLaporan = value.toString();
                    },
                    onSaved: (newValue) {
                      selectedKategoriLaporan = newValue.toString();
                    },
                  ),
                ),
                const Text(
                  'Deskripsi',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: my_colors.blue, fontWeight: FontWeight.bold),
                ),
                Container(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.only(
                            top: 0, right: 30, bottom: 0, left: 16),
                        hintText: 'Masukkan di Sini',
                      ),
                      autovalidateMode: AutovalidateMode.always,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '* wajib diisi';
                        }
                        if (value.contains(RegExp(r'[!@#%^&*()?"/;:{}|<>]'))) {
                          return 'Teks tidak boleh mengandung simbol!';
                        }

                        return null;
                      },
                    )),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_image == null) {
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                    title: const Text('IRSMS'),
                                    content:
                                        const Text('Gambar belum diambil.'),
                                    actions: [
                                      TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Tutup'))
                                    ],
                                  ));
                        } else if (_formKey.currentState!.validate() &&
                            !isLoading) {
                          _submit();
                        }
                      },
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(my_colors.blue),
                        padding:
                            MaterialStateProperty.all(const EdgeInsets.all(16)),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                      child: (isLoading)
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 1.5,
                              ),
                            )
                          : const Text(
                              'Kirim',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                    )),
              ],
            ),
          ),
        )),
      ),
    );
  }
}

/**
class CardPicture extends StatefulWidget {
  const CardPicture({super.key});

  @override
  State<CardPicture> createState() => _CardPictureState();
}

class _CardPictureState extends State<CardPicture> {
  final ImagePicker _picker = ImagePicker();
  File? image;

  imageSelectorCamera() async {
    XFile? xFile = await _picker.pickImage(source: ImageSource.camera, maxWidth: 300, maxHeight: 300);
    if (xFile != null) {
      image = File(xFile.path);
      setState(() {
        
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Center(
        child: Card(
          elevation: 3,
          child: InkWell(
            onTap: imageSelectorCamera,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
              width: 260,
              height: 360,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: (image == null
                        ? Text(
                            'Ambil gambar!',
                            style: TextStyle(fontSize: 17, color: Colors.grey[600]),
                          )
                        : Image.file(image!, fit: BoxFit.fitHeight, width: 300, height: 300,)),
                  ),
                  Icon(
                    Icons.photo_camera,
                    color: Colors.indigo[400],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
*/
