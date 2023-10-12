import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mapviewapp/map_screen.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:mapviewapp/utils/images.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home:   MapPage(),
    );
  }
}




class CarMovementMap extends StatefulWidget {
  @override
  _CarMovementMapState createState() => _CarMovementMapState();
}

class _CarMovementMapState extends State<CarMovementMap> {
  GoogleMapController? mapController;
  Set<Polyline> polylines = {};
  LatLng? currentCarPosition;
  List<LatLng> routeCoordinates = [
    LatLng(9.3853, 76.5750),
    LatLng(9.5916, 76.5222),
  ];

  int currentCoordinateIndex = 0;
  bool isMoving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Car Movement Between Polylines'),
      ),
      body: GoogleMap(
        onMapCreated: (controller) {
          mapController = controller;
          drawRoute();
        },
        initialCameraPosition: CameraPosition(
          target: routeCoordinates.first,
          zoom: 12.0,
        ),
        polylines: polylines,
        markers: {
          Marker(
            markerId: MarkerId('car'),
            position: currentCarPosition ?? routeCoordinates.first,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: toggleCarMovement,
        child: Icon(isMoving ? Icons.stop : Icons.play_arrow),
      ),
    );
  }

  void drawRoute() {
    Polyline route = Polyline(
      polylineId: PolylineId("route"),
      color: Colors.blue,
      points: routeCoordinates,
    );

    setState(() {
      polylines.add(route);
    });
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
      animateCarMovement(routeCoordinates[currentCoordinateIndex], routeCoordinates[currentCoordinateIndex + 1]);
    }
  }

  void stopCarMovement() {
    isMoving = false;
  }

  void animateCarMovement(LatLng from, LatLng to) {
    const duration = Duration(seconds: 5);
    final distance = LatLngUtil.distance(from, to);
    final speed = distance! / duration.inSeconds;
    final stepDistance = speed * 0.25;

    final direction = LatLngUtil.bearing(from, to);

    animateCar(from, to, direction, stepDistance, duration);
  }

  void animateCar(LatLng from, LatLng to, double direction, double stepDistance, Duration duration) {
    final distance = LatLngUtil.distance(from, to);
    final totalSteps = (distance! / stepDistance).ceil();

    final stepLat = (to.latitude - from.latitude) / totalSteps;
    final stepLng = (to.longitude - from.longitude) / totalSteps;

    final stopwatch = Stopwatch()..start();
    Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (stopwatch.elapsed < duration) {
        final step = (stopwatch.elapsed.inMilliseconds / 250).floor();
        final lat = from.latitude + step * stepLat;
        final lng = from.longitude + step * stepLng;
        final position = LatLng(lat, lng);

        setState(() {
          currentCarPosition = position;
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
  static double? distance(LatLng start, LatLng end) {
    final p = 0.017453292519943295;
    final a = 0.5 - cos((end.latitude - start.latitude) * p) / 2 +
        cos(start.latitude * p) * cos(end.latitude * p) * (1 - cos((end.longitude - start.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  static double bearing(LatLng start, LatLng end) {
    final startLat = start.latitude * pi / 180;
    final startLng = start.longitude * pi / 180;
    final endLat = end.latitude * pi / 180;
    final endLng = end.longitude * pi / 180;

    final dLng = endLng - startLng;

    final y = sin(dLng) * cos(endLat);
    final x = cos(startLat) * sin(endLat) - sin(startLat) * cos(endLat) * cos(dLng);

    return (atan2(y, x) * 180 / pi + 360) % 360;
  }
}
