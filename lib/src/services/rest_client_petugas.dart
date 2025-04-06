import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class RestClientPetugas {
  // API CI4
//  String get baseURL => 'http://10.0.2.2:8080';
//  String get baseURL => 'https://v2.irsmsdev.xyz/irsmsmobile';
  String get baseURL => 'https://irsms.korlantas.polri.go.id/irsmsmobile';

  /// GET method
  ///
  /// @param {String} controller Controller/method
  ///
  Future<Map<String, dynamic>> get(
      {required String controller,
      required Map<String, dynamic> params}) async {
    String url = '$baseURL/index.php/$controller?';

    params.forEach((key, value) {
      url += '&$key=$value';
    });

    var response = await http.get(Uri.parse(url));
    var json = convert.jsonDecode(response.body);
    var results = json as Map<String, dynamic>;

    if (results.containsKey('message')) {
      return {'status': false, 'error': results['message']};
    }
    return results;
  }

  /// Upload gambar
  ///
  /// @params {paths} paths Lokasi file gambar
  Future<Map<String, dynamic>> uploadPhotos(List<String> paths) async {
    Uri uri = Uri.parse('$baseURL/index.php/upload');
    http.MultipartRequest request = http.MultipartRequest('POST', uri);
    for (String path in paths) {
      request.files.add(await http.MultipartFile.fromPath('files[]', path));
    }

    try {
      http.StreamedResponse response = await request.send();

      var responseBytes = await response.stream.toBytes();
      var responseString = convert.utf8.decode(responseBytes);

      return convert.jsonDecode(responseString);
    } catch (e) {
      return {'status': false, 'error': 'koneksi internet terputus'};
    }
  }

  /// POST method
  ///
  /// @param {String} token Token
  ///
  /// @param {String} controller REST Api Controller
  ///
  /// @param {Map<String, dynamic>} data Data yang dikirim
  Future<Map<String, dynamic>> post(
      {required String controller,
      required Map<String, dynamic> data,
      String? token}) async {
    String uri = '$baseURL/index.php/$controller';
    if (token != null) {
      uri += '?token=$token';
    }

    try {
      var response = await http.post(
        Uri.parse(uri),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: convert.jsonEncode(data),
      );
      var json = convert.jsonDecode(response.body);
      var results = json as Map<String, dynamic>;

      if (results.containsKey('message')) {
        return {'status': false, 'error': results['message']};
      }
      return results;
    } catch (e) {
      return {'status': false, 'error': 'koneksi internet terputus'};
    }
  }

  /// PUT method
  ///
  /// @param {String} controller REST Api Controller
  ///
  /// @param {Map<String, dynamic>} params Params
  ///
  /// @param {Map<String, dynamic>} data Data yang dikirim
  Future<Map<String, dynamic>> put(
      {required String controller,
      required Map<String, dynamic> params,
      required Map<String, dynamic> data}) async {
    String uri = '$baseURL/index.php/$controller?';
    params.forEach((key, value) {
      uri += '&$key=$value';
    });

    try {
      var response = await http.put(
        Uri.parse(uri),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: convert.jsonEncode(data),
      );

      var json = convert.jsonDecode(response.body);
      var results = json as Map<String, dynamic>;

      if (results.containsKey('message')) {
        return {'status': false, 'error': results['message']};
      }

      return results;
    } catch (e) {
      return {'status': false, 'error': 'koneksi internet terputus'};
    }
  }
}
