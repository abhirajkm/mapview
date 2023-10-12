import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mapviewapp/utils/images.dart';

const String GOOGLE_MAPS_API_KEY = "AIzaSyBi6BJ8ooZF1uqy7Lp7lFwBQoopklaPO1M";

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  GoogleMapController? mapController;

  LatLng? startPoint;
  LatLng? endPoint;
  BitmapDescriptor? start;
  BitmapDescriptor? stop;
  BitmapDescriptor? carIcon1;
  final Set<Marker> _markers = <Marker>{};
  final Set<Polyline> _directionPolyline = {};
  List<LatLng> polylineCoordinates = [];

  LatLng? currentCarPosition;
  List<LatLng> routeCoordinates = [];

  int currentCoordinateIndex = 0;
  bool isMoving = false;

  void _onMapCreated(GoogleMapController controller) {
    _mapController.complete(controller);
    mapController = controller;
    _getPolyline();
  }

  Future<void> setStartPoint(LatLng position) async {
    setState(() {
      startPoint = position;
      routeCoordinates.add(startPoint!);
    });
  }

  Future<void> setEndPoint(LatLng position) async {
    setState(() {
      endPoint = position;
      routeCoordinates.add(endPoint!);
    });
  }

  void reset() {
    setState(() {
      endPoint = null;
      startPoint = null;
      routeCoordinates.clear();
      _markers.clear();
      polylineCoordinates.clear();
    });
  }

  void showCarDetails() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        // Create and return a widget with car details
        return SizedBox(height: 100, child: CarDetailsWidget());
      },
    );
  }

  void addPoint(LatLng point) {
    setState(() {
      if (startPoint == null) {
        setStartPoint(point);

        _markers.add(Marker(
            markerId: const MarkerId('start'),
            position: routeCoordinates.first,
            icon: start ??
                BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen),
            onTap: showCarDetails));
      } else if (endPoint == null) {
        setEndPoint(point);
        _markers.add(Marker(
          markerId: const MarkerId('end'),
          position: routeCoordinates.last,
          icon: stop ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));
        _getPolyline();
      } else if (currentCarPosition != null) {
        setEndPoint(point);
        _markers.add(Marker(
          markerId: const MarkerId('car'),
          position: currentCarPosition!,
          icon: carIcon1 ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));
        _getPolyline();
      }

      else {
        setStartPoint(point);
        reset();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _getPolyline();
    getCarIcon();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: toggleCarMovement,
        child: Icon(isMoving ? Icons.stop : Icons.play_arrow),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: LatLng(9.6259, 76.5405),
                zoom: 13,
              ),
              markers: _markers,
              polylines: _directionPolyline,
              onTap: (LatLng position) {
                addPoint(position);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> getBytesFromAsset(
    String path,
  ) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: 70);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  getCarIcon() async {
    final Uint8List startIcon = await getBytesFromAsset(iconStart);
    start = BitmapDescriptor.fromBytes(startIcon);
    final Uint8List stopIcon = await getBytesFromAsset(iconStop);
    stop = BitmapDescriptor.fromBytes(stopIcon);
    final Uint8List carIcon = await getBytesFromAsset(iconStop);
    carIcon1 = BitmapDescriptor.fromBytes(carIcon);
  }

  _getPolyline() async {
    Polyline polyLine = Polyline(
        polylineId: const PolylineId('direction'),
        color: Colors.green,
        points: routeCoordinates,
        width: 3,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
        geodesic: false);
    polyLine.points.add(LatLng(startPoint!.latitude, startPoint!.longitude));
    polyLine.points.add(LatLng(endPoint!.latitude, endPoint!.longitude));
    _directionPolyline.add(polyLine);
  }

  void toggleCarMovement() {
    if (isMoving) {
      stopCarMovement();
    } else {
      startCarMovement();
    }
  }

  void startCarMovement() {
    if (currentCoordinateIndex < routeCoordinates.length - 1) {
      isMoving = true;
      animateCarMovement(routeCoordinates[currentCoordinateIndex],
          routeCoordinates[currentCoordinateIndex + 1]);
    }
  }

  void stopCarMovement() {
    isMoving = false;
  }

  void animateCarMovement(LatLng from, LatLng to) {
    const duration = Duration(milliseconds: 1000);
    final distance = LatLngUtil.distance(
        from.latitude, from.longitude, to.latitude, to.longitude);
    final speed = distance / duration.inSeconds;
    final stepDistance = speed * 0.25;

    final direction = LatLngUtil.bearing(from, to);

    animateCar(from, to, direction, stepDistance, duration);
  }

  void animateCar(LatLng from, LatLng to, double direction, double stepDistance,
      Duration duration) {
    final distance = LatLngUtil.distance(
        from.latitude, from.longitude, to.latitude, to.longitude);
    final totalSteps = (distance / stepDistance).ceil();

    final stepLat = (to.latitude - from.latitude) / totalSteps;
    final stepLng = (to.longitude - from.longitude) / totalSteps;

    final stopwatch = Stopwatch()..start();
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (stopwatch.elapsed < duration) {
        final step = (stopwatch.elapsed.inMilliseconds / 250).floor();
        final lat = from.latitude + step * stepLat;
        final lng = from.longitude + step * stepLng;
        final position = LatLng(lat, lng);

        setState(() {
          currentCarPosition = position;
          print("aaaaaaaa$currentCarPosition");
        });
      } else {
        timer.cancel();
        setState(() {
          currentCoordinateIndex++;
          if (currentCoordinateIndex < routeCoordinates.length - 1) {
            startCarMovement();
          } else {
            isMoving = false;
          }
        });
      }
    });
  }
}

class LatLngUtil {
  static double distance(double startLatitude, double startLongitude,
      double endLatitude, double endLongitude) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((endLatitude - startLatitude) * p) / 2 +
        cos(startLatitude * p) *
            cos(endLatitude * p) *
            (1 - cos((endLongitude - startLongitude) * p)) /
            2;
    return 12742 * asin(sqrt(a));
  }

  static double bearing(LatLng start, LatLng end) {
    final startLat = start.latitude * (pi / 180.0);
    final startLng = start.longitude * (pi / 180.0);
    final endLat = end.latitude * (pi / 180.0);
    final endLng = end.longitude * (pi / 180.0);

    final dLng = endLng - startLng;

    final y = sin(dLng) * cos(endLat);
    final x =
        cos(startLat) * sin(endLat) - sin(startLat) * cos(endLat) * cos(dLng);
    return atan2(y, x) * (180.0 / pi);
  }
}

class CarDetailsWidget extends StatelessWidget {
  const CarDetailsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: const [
          Text('Moving Car Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Model: Kia'),
          Text('Sonnet'),
        ],
      ),
    );
  }
}
