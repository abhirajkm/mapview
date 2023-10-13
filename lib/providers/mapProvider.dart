import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:mapviewapp/utils/images.dart';

import '../map_screen.dart';

class MapProvider with ChangeNotifier {
  GoogleMapController? mapController;

  LatLng? startPoint;
  LatLng? endPoint;
  BitmapDescriptor? start;
  BitmapDescriptor? stop;
  BitmapDescriptor? carIcon1;
  final Set<Marker> markers = <Marker>{};
  final Set<Polyline> directionPolyline = {};
  List<LatLng> polylineCoordinates = [];
  LatLng? currentCarPosition;
  List<LatLng> routeCoordinates = [];
  int currentCoordinateIndex = 0;
  bool isMoving = false;

  double carRotation = 0;



  void startCarMovement() {
    isMoving = true;
    if (currentCoordinateIndex < routeCoordinates.length - 1) {
      //animateCarMovement(routeCoordinates[currentCoordinateIndex],
         // routeCoordinates[currentCoordinateIndex + 1]);
    }
    notifyListeners();
  }

  void stopCarMovement() {
    isMoving = false;
    notifyListeners();
  }

  setCurrentPosition(LatLng position){
    currentCarPosition=position;
    notifyListeners();
  }


  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    addPolyLine();
  }

  Future<void> setStartPoint(LatLng position) async {
    startPoint = position;
    routeCoordinates.add(startPoint!);
    notifyListeners();
  }

  Future<void> setEndPoint(LatLng position) async {
    endPoint = position;
    routeCoordinates.add(endPoint!);
    notifyListeners();
  }

   movableMarker(){
    Timer(const Duration(seconds: 10), () {
      markers.add(
          Marker(
            markerId: const MarkerId("dest"),
            position: currentCarPosition??LatLng(9.6115, 76.5335),


          ),
        );
      notifyListeners();
      });

  }



  void reset() {
    endPoint = null;
    startPoint = null;
    routeCoordinates.clear();
    markers.clear();
    polylineCoordinates.clear();
    notifyListeners();
  }



  addPolyLine() async {
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
    directionPolyline.add(polyLine);
  }

  toggleCarMovement() {
    if (isMoving) {
      stopCarMovement();
    } else {
      startCarMovement();
    }
    notifyListeners();
  }
  Future<void> animateCarMovement()  async{
    await Future.delayed(const Duration(seconds: 5), () {
      if (currentCoordinateIndex < routeCoordinates.length - 1) {
        final from = routeCoordinates[currentCoordinateIndex];
        final to = routeCoordinates[currentCoordinateIndex + 1];

        double distance = LatLngUtil.distance(
            from.latitude, from.longitude, to.latitude, to.longitude);
        double fraction = 0.0;


          currentCarPosition = from;



        const duration = Duration(seconds: 2);


        mapController?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: from, zoom: 12.0),
        ));

        Timer.periodic(Duration(milliseconds: 500), (timer) {
          fraction += 16 / duration.inMilliseconds;
          if (fraction < 1.0) {
            final lat = lerpDouble(from.latitude, to.latitude, fraction);
            final lng = lerpDouble(from.longitude, to.longitude, fraction);
            final rotation = LatLngUtil.bearing(from, to);

              currentCarPosition = LatLng(lat!, lng!);
              carRotation = rotation;
              print("Current Car Position Prints => $currentCarPosition");

          } else {
            currentCoordinateIndex++;
            timer.cancel();
            animateCarMovement();
          }
        });
      }
    }
    );

  }

 /* void animateCarMovement(LatLng from, LatLng to) {
    const duration = Duration(milliseconds: 5);
    final distance = LatLngUtil.distance(
        from.latitude, from.longitude, to.latitude, to.longitude);
    final speed = distance / duration.inSeconds;
    final stepDistance = speed * 0.25;

    final direction = LatLngUtil.bearing(from, to);

    animateCar(from, to, direction, stepDistance, duration);
  }*/

  void animateCar(LatLng from, LatLng to, double direction, double stepDistance,
      Duration duration) {
    final distance = LatLngUtil.distance(
        from.latitude, from.longitude, to.latitude, to.longitude);
    final totalSteps = (distance / stepDistance).ceil();

    final stepLat = (to.latitude - from.latitude) / totalSteps;
    final stepLng = (to.longitude - from.longitude) / totalSteps;

    final stopwatch = Stopwatch()..start();
    Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (stopwatch.elapsed < duration) {
        final step = (stopwatch.elapsed.inMilliseconds / 250).floor();
        final lat = from.latitude + step * stepLat;
        final lng = from.longitude + step * stepLng;
        final position = LatLng(lat, lng);

        currentCarPosition = position;
        print("position updating$currentCarPosition");
      } else {
        timer.cancel();
        currentCoordinateIndex++;
        if (currentCoordinateIndex < routeCoordinates.length - 1) {
          startCarMovement();
        } else {
          isMoving = false;
        }
      }
      notifyListeners();
    });
  }
}
