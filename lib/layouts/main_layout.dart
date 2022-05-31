// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StreamSubscription? _locationSubscription;
  Location _locationTracker = Location();
  Marker? marker;
  Circle? circle;
  GoogleMapController? _controller;
  Set<Polyline> pathPolyline = <Polyline>{};
  List<LatLng>lL= <LatLng>[];





  static final CameraPosition initialLocation = CameraPosition(
    target: LatLng(30.069128221241392, 31.31227016074638),
    zoom: 19.4746,
  );

  Future<Uint8List> getMarker() async {
    ByteData byteData = await DefaultAssetBundle.of(context).load("assets/delivery.png");
    return byteData.buffer.asUint8List();
  }

  void updateMarkerAndCircleAndPath(LocationData newLocalData, Uint8List imageData) {
    LatLng latlng = LatLng(newLocalData.latitude!, newLocalData.longitude!);
    setState(() {
      marker = Marker(
          markerId: MarkerId("home"),
          position: latlng,
          rotation: newLocalData.heading!,
          draggable: false,
          zIndex: 2,
          flat: true,
          anchor: Offset(0.5, 0.5),
          icon: BitmapDescriptor.fromBytes(imageData)
      );
      circle = Circle(
          circleId: CircleId("car"),
          radius: newLocalData.accuracy!,
          zIndex: 1,
          strokeColor: Colors.blue,
          center: latlng,
          fillColor: Colors.blue.withAlpha(70));
      lL.add(latlng);
      pathPolyline.add(
        Polyline(
            polylineId: PolylineId('1'),
            color: Colors.yellow,
            width: 5,
            points:lL,
            patterns: [
              PatternItem.dash(20),
              PatternItem.gap(10),
            ]

        ),
      );

    });
  }

  void getCurrentLocation() async {
    try {

      Uint8List imageData = await getMarker();

      var location = await _locationTracker.getLocation();

      updateMarkerAndCircleAndPath(location, imageData);

      if (_locationSubscription != null) {
        _locationSubscription!.cancel();
      }


      _locationSubscription = _locationTracker.onLocationChanged.listen((newLocalData) {
        if (_controller != null) {
          _controller!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
              bearing: 90.8334901395799,
              target: LatLng(newLocalData.latitude!, newLocalData.longitude!),
              tilt: 0,
              zoom: 18.00)));
          updateMarkerAndCircleAndPath(newLocalData, imageData);
        }
      });

    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        debugPrint("Permission Denied");
      }
    }
  }

  @override
  void dispose() {
    if (_locationSubscription != null) {
      _locationSubscription!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Directionality(
            textDirection: TextDirection.rtl,
            child: Center(child: Text(widget.title!))),
      ),
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: initialLocation,
        markers: Set.of((marker != null) ? [marker!] : []),
        circles: Set.of((circle != null) ? [circle!] : []),
        polylines: pathPolyline,
        onMapCreated: (GoogleMapController controller) {
          _controller = controller;
        },

      ),
      floatingActionButton: Container(
        padding: EdgeInsets.only(right: 35, ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(

                child: Icon(Icons.location_searching),
                onPressed: () {
                  getCurrentLocation();
                }),
            SizedBox(width: 5,),
            FloatingActionButton(

                child: Icon(Icons.close),
                onPressed: () {
                  if (_locationSubscription != null) {
                    _locationSubscription!.cancel();
                  }
                }),
          ],
        ),
      ),
    );
  }
}
