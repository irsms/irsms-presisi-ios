import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../libraries/colors.dart' as my_colors;
import '../services/rest_client.dart';
import 'package:bcrypt/bcrypt.dart';

class ResetPasswordProfile extends StatefulWidget {
  const ResetPasswordProfile({super.key});

  @override
  State<ResetPasswordProfile> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPasswordProfile> {
  final _formKey = GlobalKey<FormState>();
  bool showPassword = false;

  final TextEditingController _passwordNewController = TextEditingController();
  final TextEditingController _passwordBeforeController =
      TextEditingController();

  bool isLoading = false;

  // Fungsi untuk menampilkan dialog kesalahan
  void _showPasswordErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Password Salah"),
          content: Text("Password lama yang Anda masukkan tidak cocok."),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Tutup dialog
                Navigator.of(context).pop();
              },
              child: Text("Tutup"),
            ),
          ],
        );
      },
    );
  }

  void _submit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //   String id = prefs.getString('masyarakat__members_id') ?? '';
    String token = prefs.getString('token') ?? '';

    isLoading = true;
    setState(() {});

    var controller = 'masyarakat/profile';
    var params = {'token': token};
    Map<String, dynamic> profile =
        await RestClient().get(controller: controller, params: params);

    var _profile = profile['rows'][0];
    String id = _profile['masyarakat__members_id'] ?? '';
    // print(id);

    if (profile['status']) {
      bool isOldPasswordCorrect = BCrypt.checkpw(
        _passwordBeforeController.text, // Input old password
        _profile['password'], // Stored hashed password
      );
      if (isOldPasswordCorrect) {
        Map<String, dynamic> data = {"password": _passwordNewController.text};
        Map<String, dynamic> params = {
          "token": token,
          "masyarakat__members_id": id,
        };
        var controller = 'masyarakat/reset_password';
        var resp = await RestClient()
            .put(controller: controller, data: data, params: params);

        if (resp['status']) {
          await Future.delayed(const Duration(seconds: 0));
          if (!mounted) return;

          isLoading = false;
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password Anda berhasil diupdate'),
              duration: Duration(seconds: 3), // Durasi tampil snackbar
              backgroundColor: Colors.blue, // Warna background snackbar
            ),
          );
          Navigator.pushNamed(context, '/');
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
        _showPasswordErrorDialog();
        isLoading = false;
        setState(() {});
        // Password salah, beri pesan kesalahan
      }
    } else {
      if (!mounted) return;
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('IRSMS'),
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

    // isLoading = true;
    // setState(() {});

    // Map<String, dynamic> data = {"password": _passwordController.text};
    // Map<String, dynamic> params = {
    //   "token": token,
    //   "masyarakat__members_id": id,
    // };
    // var controller = 'masyarakat/reset_password';
    // var resp = await RestClient()
    //     .put(controller: controller, data: data, params: params);

    // if (resp['status']) {
    //   await Future.delayed(const Duration(seconds: 0));
    //   if (!mounted) return;

    //   isLoading = false;
    //   setState(() {});
    //   Navigator.pushNamed(context, '/');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Reset Password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Sandi sebelumnya',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: my_colors.blue, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: TextFormField(
                      obscureText: showPassword ? false : true,
                      controller: _passwordBeforeController,
                      autovalidateMode: AutovalidateMode.always,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '* wajib diisi';
                        }

                        //   if (value.length < 8) {
                        //     return 'Panjang password minimal 8 karakter';
                        //   }

                        //   bool lcaseMatch = RegExp('[a-z]').hasMatch(value);
                        //   if (!lcaseMatch) {
                        //     return 'Password minimal mengandung 1 huruf kecil';
                        //   }

                        //   bool ucaseMatch = RegExp('[A-Z]').hasMatch(value);
                        //   if (!ucaseMatch) {
                        //     return 'Password minimal mengandung 1 huruf kapital';
                        //   }

                        //   bool numberMatch = RegExp('[0-9]').hasMatch(value);
                        //   if (!numberMatch) {
                        //     return 'Password minimal mengandung 1 angka';
                        //   }

                        //   bool specialMatch =
                        //       RegExp('[!,%,&,@,#,\$,^,*,?,_,~]').hasMatch(value);
                        //   if (!specialMatch) {
                        //     return 'Password minimal mengandung 1 karakter spesial';
                        //   }

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
                    'Sandi Baru',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: my_colors.blue, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: TextFormField(
                      obscureText: showPassword ? false : true,
                      controller: _passwordNewController,
                      autovalidateMode: AutovalidateMode.always,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '* wajib diisi';
                        }

                        if (value.length < 8) {
                          return 'Panjang password minimal 8 karakter';
                        }

                        bool lcaseMatch = RegExp('[a-z]').hasMatch(value);
                        if (!lcaseMatch) {
                          return 'Password minimal mengandung 1 huruf kecil';
                        }

                        bool ucaseMatch = RegExp('[A-Z]').hasMatch(value);
                        if (!ucaseMatch) {
                          return 'Password minimal mengandung 1 huruf kapital';
                        }

                        bool numberMatch = RegExp('[0-9]').hasMatch(value);
                        if (!numberMatch) {
                          return 'Password minimal mengandung 1 angka';
                        }

                        bool specialMatch =
                            RegExp('[!,%,&,@,#,\$,^,*,?,_,~]').hasMatch(value);
                        if (!specialMatch) {
                          return 'Password minimal mengandung 1 karakter spesial';
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
                  const Text(
                    'Konfirmasi Sandi Baru',
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

                        if (value != _passwordNewController.text) {
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
                            _submit();
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
                                'Reset Password',
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
