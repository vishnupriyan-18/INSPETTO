// Handles GPS location capture and reverse geocoding
// Member 2 (Field Officer screens) uses this
import 'package:flutter/material.dart';

class LocationProvider extends ChangeNotifier {
  double? latitude;
  double? longitude;
  String? address;

  // TODO: get current GPS location
  Future<void> getCurrentLocation() async {}

  // TODO: convert GPS to address name
  Future<String> getAddressFromCoords(double lat, double lng) async => '';
}
