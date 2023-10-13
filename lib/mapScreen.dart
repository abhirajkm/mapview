import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:mapviewapp/providers/mapProvider.dart';
import 'package:mapviewapp/utils/images.dart';
import 'package:mapviewapp/utils/view.dart';
import 'package:provider/provider.dart';


class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  _MapViewScreenState createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {

  GoogleMapController? mapController;
  Set<Polyline> polylines = {};
  LatLng? currentCarPosition;
  int currentCoordinateIndex = 0;
  double carRotation = 0;
  BitmapDescriptor? start;
  BitmapDescriptor? stop;
  BitmapDescriptor? car;
  Timer? _timer;



  getIcon() async {
    final Uint8List startIcon = await getBytesFromAsset(iconStart);
    start = BitmapDescriptor.fromBytes(startIcon);
    final Uint8List stopIcon = await getBytesFromAsset(iconStop);
    stop = BitmapDescriptor.fromBytes(stopIcon);
    final Uint8List carIcon = await getBytesFromAsset(iconCar3);
    car = BitmapDescriptor.fromBytes(carIcon);
  }

  @override
  void initState() {
    getIcon();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Car Movement Between Polylines'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _timer?.cancel();
            Provider.of<MapProvider>(context,listen: false).reset();
            setState(() {
              polylines.clear();

            });
          },
          child: Icon(Icons.clear),
        ),
        body: Consumer<MapProvider>(
          builder: (context,v,child) {
            return GoogleMap(
              onMapCreated: (controller) {
                mapController = controller;
                //setState(() {
                //  animateCarMovement();
                //});
              },
              initialCameraPosition: const CameraPosition(
                target: LatLng(9.5916, 76.5222),
                zoom: 12.0,
              ),
              markers: v.markers,
              polylines: <Polyline>{
                if (v.routeCoordinates != null)
                  Polyline(
                    polylineId: const PolylineId("route"),
                    color: Colors.green,
                    points: v.routeCoordinates,
                  ),
              },
              onTap: (LatLng position) {

                  setState(() {

                      markerPoints(position);

                });
              },
            );
          }
        )
      );
  }

  Future<void> markerPoints(LatLng position) async {
    final map = Provider.of<MapProvider>(context, listen: false);
    if (map.startPoint == null) {
      map.setStartPoint(position);
      map.markers.add(Marker(
          markerId: const MarkerId("source"),
          position: map.routeCoordinates.first,
          icon:start??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan)));
    } else if (map.endPoint == null) {
      map.setEndPoint(position);
      map.markers.add(
        Marker(
          markerId: const MarkerId("destination"),
          position: map.routeCoordinates.last,
          icon: stop!
        ),
      );


       animateCarMovement();


    } else {
      _timer?.cancel();
      map.reset();
      setState(() {
        polylines.clear();
      });
    }
  }


  void animateCarMovement()  {
    final map = Provider.of<MapProvider>(context, listen: false);
    Future.delayed(const Duration(seconds: 2), () {
      if (currentCoordinateIndex < map.routeCoordinates.length - 1) {
        final from = map.routeCoordinates[currentCoordinateIndex];
        final to = map.routeCoordinates[currentCoordinateIndex + 1];


        double fraction = 0.0; const duration = Duration(seconds: 1);


          mapController?.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: from, zoom: 12.0),
          ));

        _timer  = Timer.periodic(const Duration(milliseconds: 500), (timer) {
          fraction += 16 / duration.inMilliseconds;
          if (fraction < 1.0) {
            final lat = lerpDouble(from.latitude, to.latitude, fraction);
            final lng = lerpDouble(from.longitude, to.longitude, fraction);
            final rotation = LatLngUtil.bearing(from, to);

            setState(() {
              currentCarPosition = LatLng(lat!, lng!);
             map.updateMarker(currentCarPosition!,car!,showCarDetails);
              carRotation = rotation;
              debugPrint("Current Car Position => $currentCarPosition");
            });
          } else {
            currentCoordinateIndex++;
            _timer?.cancel();
            //animateCarMovement();
          }
        });
      }
    });
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
  void showCarDetails() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return const SizedBox(height: 200, child: CarDetailsWidget());
      },
    );
  }
}




class CarDetailsWidget extends StatelessWidget {
  const CarDetailsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children:  [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:  [
              const Text('Moving Car Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: ()=>Navigator.pop(context), icon: const Icon(Icons.close_rounded))
            ],
          ),
          const Text('Model: Kia'),
          const Text('Sonnet'),
        ],
      ),
    );
  }
}