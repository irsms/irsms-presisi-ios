import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import '../libraries/colors.dart' as my_colors;
import '../services/rest_client.dart';
import 'ktp.dart';
import 'dart:convert';

class Registrasi extends StatefulWidget {
  const Registrasi({super.key});

  @override
  State<Registrasi> createState() => _RegistrasiState();
}

class _RegistrasiState extends State<Registrasi> {
  final _formKey = GlobalKey<FormState>();
  RestClient restClient = RestClient();
  bool showPassword = false;
  final ImagePicker _picker = ImagePicker();
  File? _image;
  List<String> get _imagePaths => [_image!.path];

  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _namaDepanController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _namaBelakangController = TextEditingController();
  final TextEditingController _tempatLahirController = TextEditingController();
  final TextEditingController _agamaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _noHpController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

//  final TextEditingController _phoneController = TextEditingController();
  bool _isValid = true;

  String? jenisKelamin;
  List<Map<String, dynamic>> jenisKelaminList = [];

  List<Map<String, dynamic>> agamaList = [];

  DateTime tanggalLahir = DateTime.now();

  bool isLoading = false;

  Future<void> _fetchRef() async {
    try {
      var token = 'Hy6d3K1d93LOHRfbeE0KKly1YK9t4YdGsbNDEvyxAYI=irsmsmobile';
      var controller = 'ref';
      var params = {'grp_id[0]': 'G02', 'grp_id[1]': 'G03', 'token': token};
      var resp = await restClient.get(controller: controller, params: params);

      if (resp['status']) {
        for (var row in resp['rows']) {
          if (row['grp_id'] == 'G02') {
            jenisKelaminList
                .add({'value': '${row['id']}', 'title': '${row['name']}'});
          } else if (row['grp_id'] == 'G03') {
            agamaList.add({'value': '${row['id']}', 'title': '${row['name']}'});
          }
        }
      }
    } on Exception catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _res() async {
    setState(() {});

    // Navigator.pushNamed(context, '/ktp');
    // MaterialPageRoute(builder: (context) => const FaceKtp());

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FaceKtp()),
    );
  }

  Future<void> _registrasi() async {
    isLoading = true;
    setState(() {});
    //  var resps = await RestClient().uploadPhotos(_imagePaths);
    //   String fileName = resps['rows'][0]['file_name'];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String formattedDate =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    Map<String, dynamic> data = {
      "nik": _nikController.text,
      "nama_depan": _namaDepanController.text,
      "nama_belakang": _namaBelakangController.text,
      "kelamin": jenisKelamin,
      "tempat_lahir": _tempatLahirController.text,
      "tanggal_lahir": tanggalLahir.toString().substring(0, 10),
      "agama": _agamaController.text,
      "email": _emailController.text,
      "no_hp": _noHpController.text,
      "alamat": _alamatController.text,
      "username": _usernameController.text,
      "password": _passwordController.text,
      "created_at": formattedDate,
      // 'ktp': "uploads/$fileName",
    };

    // Mengubah Map menjadi JSON string
    await prefs.remove('userData');
    String jsonData = jsonEncode(data);
    await prefs.setString('userData', jsonData);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FaceKtp()),
    );
    print(prefs.getString('userData'));
    // var controller = 'masyarakat/registrasiTest';
    // var resp = await restClient.post(controller: controller, data: data);
    // String cekId = resp['id'].toString();
    // prefs.setString('_idResgister', cekId);
    // if (resp['status']) {
    //   await Future.delayed(const Duration(seconds: 3));
    //   if (!mounted) return;

    //   setState(() {
    //     isLoading = false;
    //   });

    //   //Navigator.pushNamed(context, '/ktp');
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(builder: (context) => const FaceKtp()),
    //   );
    // } else {
    //   if (!mounted) return;

    //   showDialog(
    //       context: context,
    //       builder: (context) => AlertDialog(
    //             title: const Text('IRSMS'),
    //             content: Text(resp['error']),
    //             actions: [
    //               TextButton(
    //                   onPressed: () {
    //                     setState(() {
    //                       isLoading = false;
    //                     });
    //                     Navigator.of(context).pop();
    //                   },
    //                   child: const Text('Tutup'))
    //             ],
    //           ));
    // }
  }

  void _validatePhoneNumber(String value) {
    // Gunakan ekspresi reguler (RegExp) untuk memeriksa apakah nomor telepon valid
    final RegExp phoneRegExp =
        RegExp(r'^[1-9][0-9]*$'); // Nomor telepon tidak boleh dimulai dengan 0
    setState(() {
      _isValid = phoneRegExp.hasMatch(value);
    });
  }

  Map<String, dynamic> wilayahList = {};

  Future<void> _fetchWilayahList() async {
    var token = 'token_ref';
    var controller = 'ref_wilayah';
    var resp = await restClient.get(
      controller: controller,
      params: {},
    );
    if (resp['status']) {
      setState(() {
        wilayahList = resp;
      });
    }
  }

  @override
  void initState() {
    _agamaController.text = 'G0301';
    jenisKelamin = 'G0200';

    Future.delayed(Duration.zero, () async {
      await _fetchRef();
      await _fetchWilayahList();
    });

    setState(() {});

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Registrasi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daftar Akun Masyarakat',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: my_colors.blue),
            ),
            const SizedBox(
              height: 16.0,
            ),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Informasi Dasar',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: my_colors.blue),
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'NIK',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: my_colors.blue, fontWeight: FontWeight.bold),
                  ),
                  Container(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: TextFormField(
                        controller: _nikController,
                        keyboardType: TextInputType.number,
                        autovalidateMode: AutovalidateMode.always,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '* wajib diisi';
                          }

                          if (value.length != 16) {
                            return 'Format NIK tidak sah.';
                          }
                          if (value
                              .contains(RegExp(r'[!@#%^&*(),.?":{}|<>]'))) {
                            return 'Teks tidak boleh mengandung simbol!';
                          }

                          return null;
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.only(
                              top: 0, right: 30, bottom: 0, left: 15),
                          hintText: 'Masukkan di Sini',
                        ),
                      )),
                  const Text(
                    'Nama Depan',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: my_colors.blue, fontWeight: FontWeight.bold),
                  ),
                  Container(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: TextFormField(
                        controller: _namaDepanController,
                        textCapitalization: TextCapitalization.words,
                        autovalidateMode: AutovalidateMode.always,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '* wajib diisi';
                          }
                          if (value.length > 20) {
                            return 'masukan nama depan dengan benar';
                          }
                          if (value
                              .contains(RegExp(r'[!@#%^&*(),.?":{}|<>]'))) {
                            return 'Teks tidak boleh mengandung simbol!';
                          }

                          return null;
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.only(
                              top: 0, right: 30, bottom: 0, left: 15),
                          hintText: 'Masukkan di Sini',
                        ),
                      )),
                  const Text(
                    'Nama Belakang',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: my_colors.blue, fontWeight: FontWeight.bold),
                  ),
                  Container(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: TextFormField(
                        controller: _namaBelakangController,
                        textCapitalization: TextCapitalization.words,
                        autovalidateMode: AutovalidateMode.always,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '* wajib diisi';
                          }
                          if (value.length > 20) {
                            return 'masukan nama belakang dengan benar';
                          }
                          if (value
                              .contains(RegExp(r'[!@#%^&*(),.?":{}|<>]'))) {
                            return 'Teks tidak boleh mengandung simbol!';
                          }

                          return null;
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.only(
                              top: 0, right: 30, bottom: 0, left: 15),
                          hintText: 'Masukkan di Sini',
                        ),
                      )),
                  const Text(
                    'Jenis Kelamin',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: my_colors.blue, fontWeight: FontWeight.bold),
                  ),
                  Column(
                    children: [
                      ...jenisKelaminList.map(
                        (e) {
                          return RadioListTile(
                            title: Text(e['title'].toString()),
                            value: e['value'].toString(),
                            groupValue: jenisKelamin,
                            onChanged: (value) {
                              setState(() {
                                jenisKelamin = value.toString();
                              });
                            },
                          );
                        },
                      )
                    ],
                  ),
                  const Text(
                    'Tempat Lahir',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: my_colors.blue, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: TypeAheadFormField(
                      textFieldConfiguration: TextFieldConfiguration(
                        controller: _tempatLahirController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.only(
                              top: 0, right: 30, bottom: 0, left: 16),
                          hintText: 'Masukkan di Sini',
                        ),
                      ),
                      onSuggestionSelected: ((suggestion) {
                        _tempatLahirController.text = suggestion.toString();
                      }),
                      itemBuilder: ((context, itemData) {
                        return ListTile(
                          title: Text(itemData.toString()),
                        );
                      }),
                      suggestionsCallback: (pattern) {
                        List<String> wilayah = [];
                        if (pattern.length > 2) {
                          wilayahList['rows'].forEach((item) {
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
                        if (value.length > 50) {
                          return 'masukan format dengan benar';
                        }
                        if (value.contains(RegExp(r'[!@#%^&*()?":{}|<>]'))) {
                          return 'Teks tidak boleh mengandung simbol!';
                        }

                        return null;
                      },
                    ),
                  ),
                  const Text(
                    'Tanggal Lahir',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: my_colors.blue, fontWeight: FontWeight.bold),
                  ),
                  _TanggalLahir(
                    date: tanggalLahir,
                    onChanged: (value) {
                      setState(() {
                        tanggalLahir = value;
                      });
                    },
                  ),
                  const Text(
                    'Alamat',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: my_colors.blue, fontWeight: FontWeight.bold),
                  ),
                  Container(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: TextFormField(
                        controller: _alamatController,
                        textCapitalization: TextCapitalization.words,
                        autovalidateMode: AutovalidateMode.always,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '* wajib diisi';
                          }
                          if (value.length > 50) {
                            return 'masukan format dengan benar';
                          }
                          if (value.contains(RegExp(r'[!@#%^&*()?":{}|<>]'))) {
                            return 'Teks tidak boleh mengandung simbol!';
                          }

                          return null;
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.only(
                              top: 0, right: 30, bottom: 0, left: 15),
                          hintText: 'Masukkan di Sini',
                        ),
                        maxLines: 5,
                      )),
                  const Text(
                    'Agama',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: my_colors.blue, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: DropdownButtonFormField(
                      value: _agamaController.text,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      isExpanded: true,
                      hint: const Text('Pilih Agama'),
                      icon: const Icon(Icons.keyboard_arrow_down),
                      iconSize: 30,
                      items: agamaList.map((e) {
                        return DropdownMenuItem(
                          value: e['value'], 
                          child: Text(e['title']),
                        );
                      }).toList(),
                      autovalidateMode: AutovalidateMode.always,
                      validator: (value) {
                        if (value == null) {
                          return 'Silahkan pilih agama';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _agamaController.text = value.toString();
                      },
                      onSaved: (newValue) {},
                    ),
                  ),

                  // Container(
                  //     padding: const EdgeInsets.only(bottom: 15),
                  //     child: TextFormField(
                  //       controller: _agamaController,
                  //       textCapitalization: TextCapitalization.words,
                  //       autovalidateMode: AutovalidateMode.always,
                  //       validator: (value) {
                  //         if (value == null || value.isEmpty) {
                  //           return '* wajib diisi';
                  //         }

                  //         return null;
                  //       },
                  //       decoration: InputDecoration(
                  //         border: OutlineInputBorder(
                  //             borderRadius: BorderRadius.circular(10)),
                  //         filled: true,
                  //         fillColor: Colors.white,
                  //         contentPadding: const EdgeInsets.only(
                  //             top: 0, right: 30, bottom: 0, left: 15),
                  //         hintText: 'Masukkan di Sini',
                  //       ),
                  //     )),
                  const SizedBox(
                    height: 16.0,
                  ),
                  const Text(
                    'Informasi Akun',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: my_colors.blue),
                  ),
                  const SizedBox(
                    height: 16.0,
                  ),
                  const Text(
                    'Email',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: my_colors.blue, fontWeight: FontWeight.bold),
                  ),
                  Container(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autovalidateMode: AutovalidateMode.always,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '* wajib diisi';
                          }

                          bool emailValid = RegExp(
                                  r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                              .hasMatch(value);

                          if (!emailValid) {
                            return 'Alamat email tidak sah.';
                          }

                          return null;
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.only(
                              top: 0, right: 30, bottom: 0, left: 15),
                          hintText: 'Masukkan di Sini',
                        ),
                      )),
                  const Text(
                    'Nomor Handphone',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: my_colors.blue, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: TextFormField(
                      controller: _noHpController,
                      autovalidateMode: AutovalidateMode.always,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '* wajib diisi';
                        }

                        return null;
                      },
                      onChanged: _validatePhoneNumber,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.only(
                            top: 0, right: 30, bottom: 0, left: 15),
                        hintText: 'Masukan di sini',
                        errorText:
                            _isValid ? null : 'Nomor Telepon Tidak Valid ',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(
                              15.0), // Atur padding agar selalu terlihat
                          child: Text(
                            '+62 ',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'Nama Pengguna',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: my_colors.blue, fontWeight: FontWeight.bold),
                  ),
                  // Container(
                  //   padding: const EdgeInsets.only(bottom: 15),
                  //   child: TextFormField(
                  //     controller: _usernameController,
                  //     autovalidateMode: AutovalidateMode.always,
                  //     validator: (value) {
                  //       if (value == null || value.isEmpty) {
                  //         return '* wajib diisi';
                  //       }
                  //       if (value.contains(RegExp(r'[!@#%^&*()?".,:{}|<>]'))) {
                  //         return 'Teks tidak boleh mengandung simbol!';
                  //       }

                  //       return null;
                  //     },
                  //     decoration: InputDecoration(
                  //       border: OutlineInputBorder(
                  //         borderRadius: BorderRadius.circular(10),
                  //       ),
                  //       filled: true,
                  //       fillColor: Colors.white,
                  //       contentPadding: const EdgeInsets.only(
                  //           top: 0, right: 30, bottom: 0, left: 15),
                  //       hintText: 'Masukkan di Sini',
                  //     ),
                  //   ),
                  // ),

                  Container(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: TextFormField(
                      controller: _usernameController,
                      autovalidateMode: AutovalidateMode.always,
                      onChanged: (value) {
                        // Mengganti spasi dengan karakter kosong dan mengubah huruf besar menjadi kecil
                        String formattedValue =
                            value.replaceAll(' ', '').toLowerCase();
                        _usernameController.text = formattedValue;
                        _usernameController.selection =
                            TextSelection.fromPosition(
                          TextPosition(offset: _usernameController.text.length),
                        );
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '* wajib diisi';
                        }
                        if (value.contains(RegExp(r'[!@#%^&*()?".,:{}|<>]'))) {
                          return 'Teks tidak boleh mengandung simbol!';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.only(
                            top: 0, right: 30, bottom: 0, left: 15),
                        hintText: 'Masukkan di Sini',
                      ),
                    ),
                  ),

                  const Text(
                    'Kata Sandi',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: my_colors.blue, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: TextFormField(
                      obscureText: showPassword ? false : true,
                      controller: _passwordController,
                      autovalidateMode: AutovalidateMode.always,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '* wajib diisi';
                        }

                        if (value.length < 8) {
                          return 'Panjang password minimal 8 karakter';
                        }
                        if (value.contains(RegExp(r'[!@#%^&*()?":{}|<>]'))) {
                          return 'Teks tidak boleh mengandung simbol!';
                        }

                        bool lcaseMatch = RegExp('[a-z]').hasMatch(value);
                        if (!lcaseMatch) {
                          return 'Password minimal mengandung 1 huruf kecil';
                        }

                        // bool ucaseMatch = RegExp('[A-Z]').hasMatch(value);
                        // if (!ucaseMatch) {
                        //   return 'Password minimal mengandung 1 huruf kapital';
                        // }

                        bool numberMatch = RegExp('[0-9]').hasMatch(value);
                        if (!numberMatch) {
                          return 'Password minimal mengandung 1 angka';
                        }

                        // bool specialMatch =
                        //     RegExp('[!,%,&,@,#,\$,^,*,?,_,~]').hasMatch(value);
                        // if (!specialMatch) {
                        //   return 'Password minimal mengandung 1 karakter spesial';
                        // }

                        return null;
                      },
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
                    ),
                  ),
                  const Text(
                    'Konfirmasi Kata Sandi',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: my_colors.blue, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: TextFormField(
                      obscureText: showPassword ? false : true,
                      autovalidateMode: AutovalidateMode.always,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '* wajib diisi';
                        }

                        if (value != _passwordController.text) {
                          return 'Masukkan kata sama dengan sebelumnya.';
                        }

                        return null;
                      },
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
                    ),
                  ),
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!isLoading && _formKey.currentState!.validate()) {
                            if (jenisKelamin == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Pilih jenis kelamin.')));
                            } else {
                              _registrasi();
                              //  _res();
                            }
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(my_colors.yellow),
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.all(16)),
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
                                'Verifikasi Akun',
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold),
                              ),
                      )),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _TanggalLahir extends StatefulWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _TanggalLahir({
    required this.date,
    required this.onChanged,
  });

  @override
  State<_TanggalLahir> createState() => _TanggalLahirState();
}

class _TanggalLahirState extends State<_TanggalLahir> {
  DateTime now = DateTime.now();
//  DateTime lastDate = DateTime.now(years)
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
          hintText: intl.DateFormat.yMd().format(widget.date),
          contentPadding:
              const EdgeInsets.only(top: 0, right: 30, bottom: 0, left: 15),
          suffixIcon: GestureDetector(
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 15),
              child: TextButton(
                onPressed: () async {
                  var newDate = await showDatePicker(
                    context: context,
                    initialDate: widget.date,
                    firstDate: DateTime(1900),
                    lastDate: now,
                  );

                  // Don't change the date if the date picker returns null.
                  if (newDate == null) {
                    return;
                  }

                  widget.onChanged(newDate);
                },
                child: const Icon(
                  Icons.calendar_today,
                  color: my_colors.blue,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
