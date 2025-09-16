import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class GoogleMapPlacePicker extends StatefulWidget {
  const GoogleMapPlacePicker({Key? key}) : super(key: key);

  @override
  State<GoogleMapPlacePicker> createState() => _GoogleMapPlacePickerState();
}

class _GoogleMapPlacePickerState extends State<GoogleMapPlacePicker> {
  Completer<GoogleMapController> _controller = Completer();
  LatLng? _currentLatLng;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentLatLng = LatLng(position.latitude, position.longitude);
    });

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentLatLng!,
          zoom: 16,
          tilt: 0, // force flat 2D view
          bearing: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Current Location")),
      body: _currentLatLng == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              mapType: MapType.normal, // normal 2D map
              initialCameraPosition: CameraPosition(
                target: _currentLatLng!,
                zoom: 16,
                tilt: 0, // flat top-down
                bearing: 0,
              ),
              buildingsEnabled: false, // disable 3D buildings
              indoorViewEnabled: false, // disable indoor maps
              myLocationEnabled: true, // blue dot
              myLocationButtonEnabled: true, // location button
              compassEnabled: true,
              mapToolbarEnabled: false,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<EagerGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
    );
  }
}
