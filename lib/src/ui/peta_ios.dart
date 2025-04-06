import 'dart:async';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart';
import 'package:flutter_background/flutter_background.dart';
// import 'package:mapbox_gl/mapbox_gl.dart';
import '../services/location_service.dart';
import '../services/rest_client.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class PetaIos extends StatefulWidget {
  const PetaIos({super.key});

  @override
  State<PetaIos> createState() => _PetaIosState();
}

class _PetaIosState extends State<PetaIos> {
  // late MapBoxOptions _navigationOption;
  // MapBoxNavigationViewController? _controllers;
  String? _platformVersion;
  String? _instruction;

  final bool _isMultipleStop = false;
  double? _distanceRemaining, _durationRemaining;
  bool _routeBuilt = false;
  bool _isNavigating = false;
  final bool _inFreeDrive = false;

  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  // Home
  final double _d = 0.004504505;
  late double _originLatititude = 0;
  late double _originLongitude = 0;
  late double _destinationLatitude;
  late double _destinationLongitude;
  final double _zoom = 13.0;

  final Set<Marker> _markers = <Marker>{};
  final Set<Polyline> _polyline = <Polyline>{};
  final List<PointLatLng> _pointLatLng = [];

  final _formKey = GlobalKey<FormState>();

  final RealtimeLocation _realtimeLocation = RealtimeLocation();
  late LocationData _currentPosition;
  Location location = Location();

  bool _isLoading = false;
  bool _isRouting = false;

  late Map<String, dynamic> _directions;

  final _blackspots = [];
  final _blackspotPoints = [];

  final _alertedLocations = [];

  bool _notificationEnabled = false;

  @override
  void initState() {
    super.initState();
    Platform.isIOS ? null : _enableBackgroundExecution();
    Platform.isIOS ? null : _isAndroidPermissionGranted();
    Platform.isIOS ? null : _requestPermissions();
    _setLatLng();
    //  initialize();
  }

  Future<void> _setLatLng() async {
    LocationData locationData = await location.getLocation();
    setState(() {
      _originLatititude = locationData.latitude!;
      _originLongitude = locationData.longitude!;
    });
  }

  @override
  void dispose() {
    _realtimeLocation.dispose();
    _isRouting = false;
    _isLoading = false;
    _originController.dispose();
    super.dispose();
  }

  // Future<void> initialize() async {
  //   // If the widget was removed from the tree while the asynchronous platform
  //   // message was in flight, we want to discard the reply rather than calling
  //   // setState to update our non-existent appearance.
  //   if (!mounted) return;

  //   _navigationOption = MapBoxNavigation.instance.getDefaultOptions();
  //   _navigationOption.language = 'id';
  //   //  _navigationOption.simulateRoute = true;
  //   //_navigationOption.initialLatitude = 36.1175275;
  //   //_navigationOption.initialLongitude = -115.1839524;
  //   MapBoxNavigation.instance.registerRouteEventListener(_onEmbeddedRouteEvent);
  //   MapBoxNavigation.instance.setDefaultOptions(_navigationOption);

  //   String? platformVersion;
  //   // Platform messages may fail, so we use a try/catch PlatformException.
  //   try {
  //     platformVersion = await MapBoxNavigation.instance.getPlatformVersion();
  //   } on PlatformException {
  //     platformVersion = 'Failed to get platform version.';
  //   }

  //   setState(() {
  //     _platformVersion = platformVersion;
  //   });
  // }

  // Future<void> _onEmbeddedRouteEvent(e) async {
  //   _distanceRemaining = await MapBoxNavigation.instance.getDistanceRemaining();
  //   _durationRemaining = await MapBoxNavigation.instance.getDurationRemaining();

  //   switch (e.eventType) {
  //     case MapBoxEvent.progress_change:
  //       var progressEvent = e.data as RouteProgressEvent;
  //       if (progressEvent.currentStepInstruction != null) {
  //         _instruction = progressEvent.currentStepInstruction;
  //       }
  //       break;
  //     case MapBoxEvent.route_building:
  //     case MapBoxEvent.route_built:
  //       setState(() {
  //         _routeBuilt = true;
  //       });
  //       break;
  //     case MapBoxEvent.route_build_failed:
  //       setState(() {
  //         _routeBuilt = false;
  //       });
  //       break;
  //     case MapBoxEvent.navigation_running:
  //       setState(() {
  //         _isNavigating = true;
  //       });
  //       break;
  //     case MapBoxEvent.on_arrival:
  //       if (!_isMultipleStop) {
  //         await Future.delayed(const Duration(seconds: 3));
  //         await _controllers?.finishNavigation();
  //       } else {}
  //       break;
  //     case MapBoxEvent.navigation_finished:
  //     case MapBoxEvent.navigation_cancelled:
  //       setState(() {
  //         _routeBuilt = false;
  //         _isNavigating = false;
  //       });
  //       break;
  //     default:
  //       break;
  //   }
  //   setState(() {});
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Peta IOS'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GoogleMap(
                myLocationButtonEnabled: true,
                myLocationEnabled: true,
                zoomControlsEnabled: true,
                zoomGesturesEnabled: true,
                mapType: MapType.normal,
                markers: _markers,
                polylines: _polyline,
                // circles: circles,
                initialCameraPosition: CameraPosition(
                    target: LatLng(_originLatititude, _originLongitude),
                    zoom: _zoom),
                onMapCreated: (GoogleMapController controller) async {
                  _controller.complete(controller);

                  await _setOrigin();

                  controller.animateCamera(CameraUpdate.newCameraPosition(
                      CameraPosition(
                          target: LatLng(_originLatititude, _originLongitude),
                          zoom: _zoom)));

                  _markers.add(Marker(
                      markerId: const MarkerId('Home'),
                      position: LatLng(_originLatititude, _originLongitude)));
                },
                onCameraMove: (position) async {
                  _currentPosition = await location.getLocation();

                  String address = await LocationService().getAddress(
                      latitude: _currentPosition.latitude ?? _originLatititude,
                      longitude:
                          _currentPosition.longitude ?? _originLongitude);

                  setState(() {
                    _originController.text = address;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Wrap(direction: Axis.horizontal, children: [
        FloatingActionButton.small(
          onPressed: () async {
            print('test');
            await _setOrigin();

            // setState(() {
            //   _originController.text = "KONTRAKAN UMI NAURA";
            //   _destinationController.text = "CILELES, TIGARAKSA";
            // });

            if (!mounted) return;
            print('test masuk mount');
            showModalBottomSheet(
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(8.0))),
                context: context,
                isScrollControlled: true,
                constraints: BoxConstraints(
                    maxWidth: 0.9 * MediaQuery.of(context).size.width),
                builder: (context) => Padding(
                      padding: MediaQuery.of(context).viewInsets,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TypeAheadFormField(
                                      textFieldConfiguration:
                                          TextFieldConfiguration(
                                              controller: _originController,
                                              textCapitalization:
                                                  TextCapitalization.characters,
                                              decoration: const InputDecoration(
                                                  hintText:
                                                      'Kota keberangkatan'),
                                              keyboardType:
                                                  TextInputType.multiline,
                                              maxLines: null),
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return '* wajib diisi';
                                        }

                                        return null;
                                      },
                                      onSuggestionSelected: (suggestion) {
                                        _originController.text = '$suggestion';
                                      },
                                      itemBuilder: (context, itemData) {
                                        return ListTile(
                                          title: Text('$itemData'),
                                        );
                                      },
                                      suggestionsCallback: (pattern) async {
                                        if (pattern.length > 1) {
                                          var predictions =
                                              await LocationService()
                                                  .getAutocomplete(pattern);

                                          return predictions['predictions']
                                              .map((e) => e['description']);
                                        }

                                        return [];
                                      }),
                                  TypeAheadFormField(
                                      textFieldConfiguration:
                                          TextFieldConfiguration(
                                        autofocus: true,
                                        controller: _destinationController,
                                        textCapitalization:
                                            TextCapitalization.characters,
                                        decoration: const InputDecoration(
                                            hintText: 'Kota tujuan'),
                                        keyboardType: TextInputType.multiline,
                                        maxLines: null,
                                      ),
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return '* wajib diisi';
                                        }

                                        return null;
                                      },
                                      onSuggestionSelected: (suggestion) {
                                        _destinationController.text =
                                            '$suggestion';
                                      },
                                      itemBuilder: (context, itemData) {
                                        return ListTile(
                                          title: Text('$itemData'),
                                        );
                                      },
                                      suggestionsCallback: (pattern) async {
                                        if (pattern.length > 1) {
                                          var predictions =
                                              await LocationService()
                                                  .getAutocomplete(pattern);

                                          return predictions['predictions']
                                              .map((e) => e['description']);
                                        }

                                        return [];
                                      }),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ElevatedButton(
                                  onPressed: () async {
                                    if (_isLoading == false &&
                                        _formKey.currentState!.validate()) {
                                      setState(() {
                                        _isLoading = true;
                                      });

                                      _directions = await LocationService()
                                          .getDirections(_originController.text,
                                              _destinationController.text);

                                      if (_directions['status'] == 200) {
                                        _markers.clear();
                                        _alertedLocations.clear();
                                        _blackspots.clear();
                                        _blackspotPoints.clear();

                                        _markers.add(Marker(
                                            markerId: const MarkerId('start'),
                                            position: LatLng(
                                                _directions['start_location']
                                                    ['lat'],
                                                _directions['start_location']
                                                    ['lng'])));

                                        _markers.add(Marker(
                                            // draggable: true,
                                            markerId: const MarkerId('finish'),
                                            position: LatLng(
                                                _directions['end_location']
                                                    ['lat'],
                                                _directions['end_location']
                                                    ['lng']),
                                            icon: BitmapDescriptor
                                                .defaultMarkerWithHue(
                                                    BitmapDescriptor.hueBlue),
                                            onDragEnd: (LatLng position) {
                                              // print(position);
                                            }));

                                        setState(() {});

                                        _goToPlace(
                                            _directions['start_location']
                                                ['lat'],
                                            _directions['start_location']
                                                ['lng'],
                                            _directions['bounds_ne'],
                                            _directions['bounds_sw']);

                                        _setPolyline(
                                            _directions['polyline_decoded']);

                                        _fetchBlackspot(
                                            boundsNE: _directions['bounds_ne'],
                                            boundsSW: _directions['bounds_sw'],
                                            points: _directions[
                                                'polyline_decoded']);
                                      } else {
                                        if (!mounted) return;

                                        showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                                  title: const Text('IRSMS'),
                                                  content: const Text(
                                                      'Rute tidak ditemukan. Mohon masukkan titik keberangkatan atau titik tujuan lebih lengkap.'),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        child:
                                                            const Text('Tutup'))
                                                  ],
                                                ));
                                      }
                                    }

                                    setState(() {
                                      _isLoading = false;
                                      _isRouting = true;
                                    });

                                    await Future.delayed(
                                        const Duration(seconds: 0));
                                    if (!mounted) return;
                                    Navigator.of(context).pop();
                                  },
                                  child: !_isLoading
                                      ? const Text('Cari')
                                      : const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 1,
                                          ))),
                            ),
                          ),
                        ],
                      ),
                    ));
          },
          child: const Icon(Icons.directions),
        ),
        // _isRouting
        //     ? FloatingActionButton.small(
        //         onPressed: () async {
        //           final onRoute = WayPoint(
        //               name: "Home",
        //               latitude: _originLatititude,
        //               longitude: _originLongitude,
        //               isSilent: false);
        //           final destination = WayPoint(
        //             name: "City Hall",
        //             latitude: _destinationLatitude,
        //             longitude: _destinationLongitude,
        //           );
        //           var wayPoints = <WayPoint>[];
        //           wayPoints.add(onRoute);
        //           wayPoints.add(destination);

        //           await MapBoxNavigation.instance
        //               .startNavigation(wayPoints: wayPoints);

        //           // String uri =
        //           //     'google.navigation:q=${_directions['end_location']['lat']},${_directions['end_location']['lng']}&mode=d';

        //           // final AndroidIntent intent = AndroidIntent(
        //           //     action: 'action_view',
        //           //     data: uri,
        //           //     package: 'com.google.android.apps.maps');

        //           // intent.launch();
        //         },
        //         child: const Icon(Icons.navigation),
        //       )
        //     : const SizedBox(
        //         height: 0,
        //       )
      ]),
      floatingActionButtonLocation: FloatingActionButtonLocation.startDocked,
    );
  }

  Future<void> _goToPlace(double lat, double lng, Map<String, dynamic> boundsNe,
      Map<String, dynamic> boundsSw) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: _zoom)));

    controller.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
            southwest: LatLng(boundsSw['lat'], boundsSw['lng']),
            northeast: LatLng(boundsNe['lat'], boundsNe['lng'])),
        25));
  }

  void _setPolyline(List<PointLatLng> points) {
    _pointLatLng.addAll(points);

    _polyline.clear();
    _polyline.add(Polyline(
        polylineId: const PolylineId('myRoute'),
        width: 5,
        color: Theme.of(context).primaryColor,
        points: points.map((e) => LatLng(e.latitude, e.longitude)).toList()));
  }

  Future<void> _fetchBlackspot(
      {required boundsNE,
      required boundsSW,
      required List<PointLatLng> points}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';

    String controller = 'blackspot';
    Map<String, dynamic> params = {
      'token': token,
      'bounds_ne[lat]': boundsNE['lat'],
      'bounds_ne[lng]': boundsNE['lng'],
      'bounds_sw[lat]': boundsSW['lat'],
      'bounds_sw[lng]': boundsSW['lng'],
    };

    var response =
        await RestClient().get(controller: controller, params: params);

    if (response['status'] && response['rows'].isNotEmpty) {
      late BitmapDescriptor bitmapDescriptor;

      response['rows'].forEach((item) async {
        var row = item;
        double latitude = double.parse(row['latitude']);
        double longitude = double.parse(row['longtitude']);
        Userlocation loc =
            Userlocation(latitude: latitude, longitude: longitude);

        if (row['md'] != "0") {
          bitmapDescriptor = await BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(),
            'assets/icons/car_burst/red.png',
          );
        } else if (row['lb'] != "0") {
          bitmapDescriptor = await BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(),
            'assets/icons/car_burst/yellow.png',
          );
        } else {
          bitmapDescriptor = await BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(),
            'assets/icons/car_burst/orange.png',
          );
        }

        row['bitmap'] = bitmapDescriptor;

        _blackspots.add(row);

        // if (_pointInRoute(loc)) {
        _blackspotPoints.add(row);

        setState(() {
          _markers.add(Marker(
              markerId: MarkerId(row['accident_type_id']),
              position: LatLng(latitude, longitude),
              icon: row['bitmap']));
        });
        //   }
      });
    }
  }

  bool _pointInRoute(Userlocation curLoc) {
    double d = .1 * _d;

    for (var point in _pointLatLng) {
      LatLng boundsNE = LatLng(point.latitude + d, point.longitude + d);
      LatLng boundsSW = LatLng(point.latitude - d, point.longitude - d);

      if (curLoc.latitude < boundsNE.latitude &&
          curLoc.latitude > boundsSW.latitude &&
          curLoc.longitude < boundsNE.longitude &&
          curLoc.longitude > boundsSW.longitude) {
        return true;
      }
    }

    return false;
  }

  Future<void> _setOrigin() async {
    print('Masuk kesini');
    double latitude = _originLatititude;
    double longitude = _originLongitude;
    print(latitude);
    print(longitude);
    print(_isRouting);
    if (_isRouting) {
      latitude = _directions['start_location']['lat'];
      longitude = _directions['start_location']['lng'];
    } else {
      print('masuk ke else');
      Location location = Location();
      bool serviceEnabled;
      PermissionStatus permissionGranted;
      print(location);
      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          return;
        }
      }
      print(serviceEnabled);
      permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        print('tidak diijinkan');
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          print('diijinkan');
          return;
        }
      }

      LocationData locationData = await location.getLocation();

      latitude = locationData.latitude ?? _originLatititude;
      longitude = locationData.longitude ?? _originLongitude;
    }

    String address = await LocationService()
        .getAddress(latitude: latitude, longitude: longitude);

    setState(() {
      _originController.text = address;
      _originLatititude = latitude;
      _originLongitude = longitude;
    });
  }

  Future<void> _alert(Userlocation curLoc) async {
    if (_blackspotPoints.isEmpty) return;

    double d = 0.5 * _d;

    LatLng boundsNE = LatLng(curLoc.latitude + d, curLoc.longitude + d);
    LatLng boundsSW = LatLng(curLoc.latitude - d, curLoc.longitude - d);

    if (_alertedLocations.isNotEmpty) {
      LatLng latestBoundsNE = _alertedLocations.last['boundsNE'];
      LatLng latestBoundsSW = _alertedLocations.last['boundsSW'];

      if ((curLoc.latitude < latestBoundsNE.latitude + _d &&
          curLoc.latitude > latestBoundsSW.latitude - _d &&
          curLoc.longitude < latestBoundsNE.longitude + _d &&
          curLoc.longitude > latestBoundsSW.longitude - _d)) {
        return;
      }
    }

    _alertedLocations.add({'boundsNE': boundsNE, 'boundsSW': boundsSW});

    bool isBlackspot = false;

    for (var element in _blackspotPoints) {
      double lat = double.parse(element['latitude']);
      double lng = double.parse(element['longtitude']);

      if (lat < boundsNE.latitude &&
          lat > boundsSW.latitude &&
          lng < boundsNE.longitude &&
          lng > boundsSW.longitude) {
        isBlackspot = true;
        break;
      }
    }

    if (isBlackspot) {
      String message = 'Hati-hati! Anda masuk area rawan kecelakaan.';
      await _showNotificationWithSound(message: message);
    }
  }

  Future<void> _isAndroidPermissionGranted() async {
    final bool granted = await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled() ??
        false;

    setState(() {
      _notificationEnabled = granted;
    });
  }

  Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final bool? granted = await androidImplementation?.requestPermission();
    setState(() {
      _notificationEnabled = granted ?? _notificationEnabled;
    });
  }

  Future<void> _showNotificationWithSound(
      {String title = 'IRSMS', required String message}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('irsms_alert', 'irsms_alert',
            channelDescription: 'Pemberitahuan wilayah rawan laka',
            playSound: true,
            sound: RawResourceAndroidNotificationSound('laka_warning'),
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher');

    const notificationDetails =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await FlutterLocalNotificationsPlugin()
        .show(0, title, message, notificationDetails);
  }

  Future<void> _enableBackgroundExecution() async {
    const config = FlutterBackgroundAndroidConfig(
      notificationTitle: 'IRSMS',
      notificationText: 'Aplikasi IRSMS untuk Petugas',
      //   notificationImportance: AndroidNotificationImportance.Default,
      enableWifiLock: true,
    );

    var hasPermissions = await FlutterBackground.hasPermissions;

    if (!hasPermissions) {
      if (!mounted) return;

      await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
                title: const Text('Dibutuhkan ijin'),
                content: const Text(
                    'Untuk berjalan secara penuh aplikasi membutuhkan ijin Anda untuk aplikasi berjalan di latar belakang perangkat Anda.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'OK'),
                    child: const Text('OK'),
                  ),
                ]);
          });
    }

    hasPermissions = await FlutterBackground.initialize(androidConfig: config);

    if (hasPermissions) {
      if (hasPermissions) {
        final backgroundExecution =
            await FlutterBackground.enableBackgroundExecution();

        if (backgroundExecution) {
          _realtimeLocation.locationStream.listen((userLocation) {
            if (_isRouting) {
              setState(() {
                _markers.removeWhere(
                    (Marker m) => m.markerId == const MarkerId('current'));

                _markers.add(Marker(
                    markerId: const MarkerId('current'),
                    position:
                        LatLng(userLocation.latitude, userLocation.longitude),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen)));
              });

              _alert(userLocation);
            }
          });
        }
      }
    }
  }
}

class Userlocation {
  final double latitude;
  final double longitude;

  Userlocation({required this.latitude, required this.longitude});
}

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
    await FlutterBackground.disableBackgroundExecution();
    _streamController.close();
  }
}
