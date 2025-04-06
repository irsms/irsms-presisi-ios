import 'dart:async';

import 'package:location/location.dart';

import '../models/user_location.dart';

class RealtimeLocation {
  Location location = Location();
  final StreamController<Userlocation> _streamController =
      StreamController<Userlocation>();
  Stream<Userlocation> get locationStream => _streamController.stream;

  RealtimeLocation() {
    location.requestPermission().then((permissionStatus) {
      if (permissionStatus == PermissionStatus.granted) {
        location.onLocationChanged.listen((locationData) {
          if (!_streamController.isClosed) {
            _streamController.add(Userlocation(
                latitude: locationData.latitude ?? -6.2440791,
                longitude: locationData.longitude ?? 106.854604));
          }
        });
      }
    });
  }

  Future<void> dispose() async {
    _streamController.close();
  }
}
