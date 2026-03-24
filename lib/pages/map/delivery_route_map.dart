import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class DeliveryRouteMap extends StatefulWidget {
  final double customerLat;
  final double customerLng;

  const DeliveryRouteMap({
    super.key,
    required this.customerLat,
    required this.customerLng,
  });

  @override
  State<DeliveryRouteMap> createState() => _DeliveryRouteMapState();
}

class _DeliveryRouteMapState extends State<DeliveryRouteMap> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _currentLatLng;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // 🔹 API Key from AndroidManifest
  // 🔹 API Key from AndroidManifest (for Map Display - Android Restricted)
  final String _googleMapsApiKey = "AIzaSyCBGP4AG_w_w-Nv8YJHTeBAMo1u4hADUQw";

  // 🔹 API Key for Directions API (Web Service - Unrestricted)
  final String _directionsApiKey = "AIzaSyCK9sLS7Uav0-agw9QuRlmsXv_mAttGaJc";

  @override
  void initState() {
    super.initState();
    // 1. Initialize with Customer Marker immediately so map shows instantly
    _markers = {
      Marker(
        markerId: const MarkerId("customer"),
        position: LatLng(widget.customerLat, widget.customerLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: "Customer Location"),
      ),
    };

    // 2. Fetch Location & Route
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _useFallbackLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useFallbackLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _useFallbackLocation();
        return;
      }

      // Add a timeout to prevent hanging indefinitely
      Position position =
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          ).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException("Location timeout");
            },
          );

      if (!mounted) return;

      setState(() {
        _currentLatLng = LatLng(position.latitude, position.longitude);
        _updateMarkersAndRoute();
      });
    } catch (e) {
      debugPrint("Error getting location: $e");
      _useFallbackLocation();
    }
  }

  void _useFallbackLocation() {
    if (!mounted) return;
    setState(() {
      _updateMarkersAndRoute();
    });
  }

  Future<void> _updateMarkersAndRoute() async {
    final customerLocation = LatLng(widget.customerLat, widget.customerLng);
    Set<Marker> newMarkers = {};

    // Customer Marker (Always show)
    newMarkers.add(
      Marker(
        markerId: const MarkerId("customer"),
        position: customerLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: "Customer Location"),
      ),
    );

    // Delivery Boy Marker (Only if we have location)
    if (_currentLatLng != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId("delivery_boy"),
          position: _currentLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: "You"),
        ),
      );
    }

    // 1. Show Markers Immediately
    setState(() {
      _markers = newMarkers;
    });

    _fitBounds();

    // 2. Fetch Route in Background (Only if we have both locations)
    if (_currentLatLng != null) {
      List<LatLng> polylineCoordinates = [];
      try {
        final origin =
            "${_currentLatLng!.latitude},${_currentLatLng!.longitude}";
        final destination =
            "${customerLocation.latitude},${customerLocation.longitude}";
        final url = Uri.parse(
          "https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=driving&key=$_directionsApiKey",
        );

        final response = await http
            .get(url)
            .timeout(const Duration(seconds: 10)); // Add timeout
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && (data['routes'] as List).isNotEmpty) {
            final encoded = data['routes'][0]['overview_polyline']['points'];
            polylineCoordinates = _decodePolyline(encoded);
          }
        }
      } catch (e) {
        debugPrint("Error fetching polyline: $e");
        // Fallback: simple straight line
        polylineCoordinates = [_currentLatLng!, customerLocation];
      }

      if (mounted && polylineCoordinates.isNotEmpty) {
        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId("route"),
              points: polylineCoordinates,
              color: Colors.blueAccent,
              width: 5,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          };
        });
      }
    }
  }

  // Helper to decode Google Polyline String
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Future<void> _fitBounds() async {
    final GoogleMapController controller = await _controller.future;
    final customerLocation = LatLng(widget.customerLat, widget.customerLng);

    if (_currentLatLng != null && _markers.length > 1) {
      LatLngBounds bounds;
      if (_currentLatLng!.latitude > customerLocation.latitude &&
          _currentLatLng!.longitude > customerLocation.longitude) {
        bounds = LatLngBounds(
          southwest: customerLocation,
          northeast: _currentLatLng!,
        );
      } else if (_currentLatLng!.longitude > customerLocation.longitude) {
        bounds = LatLngBounds(
          southwest: LatLng(
            _currentLatLng!.latitude,
            customerLocation.longitude,
          ),
          northeast: LatLng(
            customerLocation.latitude,
            _currentLatLng!.longitude,
          ),
        );
      } else if (_currentLatLng!.latitude > customerLocation.latitude) {
        bounds = LatLngBounds(
          southwest: LatLng(
            customerLocation.latitude,
            _currentLatLng!.longitude,
          ),
          northeast: LatLng(
            _currentLatLng!.latitude,
            customerLocation.longitude,
          ),
        );
      } else {
        bounds = LatLngBounds(
          southwest: _currentLatLng!,
          northeast: customerLocation,
        );
      }
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    } else {
      // Only customer location known
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(customerLocation, 14),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_markers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.customerLat, widget.customerLng),
        zoom: 14,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: _currentLatLng != null,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
      },
    );
  }
}
