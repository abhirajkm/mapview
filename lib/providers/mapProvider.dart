import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class MapProvider with ChangeNotifier {
  GoogleMapController? mapController;

  LatLng? startPoint;
  LatLng? endPoint;
  Set<Marker> markers = <Marker>{};
  List<LatLng> routeCoordinates = [];
  int currentCoordinateIndex = 0;





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

  void updateMarker(LatLng position,BitmapDescriptor icon,void Function() onTap) {
    List<Marker> _markers = markers.toList();
    if (markers.length < 2 ) return;
    int index = _markers.indexWhere((element) => element.markerId.value == "current");
    if (index > -1) {
      Marker marker = _markers[index];
      markers.remove(marker);
      markers.add(Marker(
          markerId: const MarkerId("current"),
          position: position,
          icon: icon,
        onTap: onTap

      ));
      notifyListeners();
    } else {
      markers.add(Marker(
          markerId: const MarkerId("current"),
          position: position,
        icon: icon,
          onTap: onTap

      ));
      notifyListeners();
    }
  }





  void reset() {
    endPoint = null;
    startPoint = null;
    routeCoordinates.clear();
    markers = {};
    notifyListeners();
  }






}
