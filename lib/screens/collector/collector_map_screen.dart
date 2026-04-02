import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/visit_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';

class CollectorMapScreen extends StatefulWidget {
  const CollectorMapScreen({super.key});

  @override
  State<CollectorMapScreen> createState() => _CollectorMapScreenState();
}

class _CollectorMapScreenState extends State<CollectorMapScreen> {
  GoogleMapController? _mapController;
  String _deptFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final district = context.watch<AuthProvider>().currentUser?.district ?? '';

    return StreamBuilder<List<VisitModel>>(
      stream: FirestoreService().getVisitsByDistrict(district),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.black));
        }

        var visits = snap.data ?? [];
        if (_deptFilter != 'All') {
          visits = visits.where((v) => v.department == _deptFilter).toList();
        }

        Set<Marker> markers = {};
        for (var v in visits) {
          double hue;
          if (v.status == 'approved') {
            hue = BitmapDescriptor.hueGreen;
          } else if (v.status == 'rejected') {
            hue = BitmapDescriptor.hueRed;
          } else {
            hue = BitmapDescriptor.hueOrange;
          }

          markers.add(Marker(
            markerId: MarkerId(v.id),
            position: LatLng(v.latitude, v.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            infoWindow: InfoWindow(
              title: '${v.department} Task',
              snippet:
                  'Progress: ${v.progress}% | Status: ${v.status.toUpperCase()}',
            ),
          ));
        }

        // Center map on Tamil Nadu generally if no visits
        LatLng initialPos = const LatLng(11.1271, 78.6569);
        if (visits.isNotEmpty) {
          initialPos = LatLng(visits.first.latitude, visits.first.longitude);
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(initialPos, 10),
          );
        }

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: initialPos, zoom: 7),
              markers: markers,
              onMapCreated: (ctrl) => _mapController = ctrl,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'All', 'TNRD', 'TWAD', 'Highways', 'Municipality', 'Corporation'
                  ].map((dept) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(dept, style: const TextStyle(fontSize: 12)),
                      selected: _deptFilter == dept,
                      onSelected: (_) => setState(() => _deptFilter = dept),
                      selectedColor: Colors.black,
                      checkmarkColor: Colors.white,
                      backgroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: Colors.black26,
                      labelStyle: TextStyle(
                          color: _deptFilter == dept
                              ? Colors.white
                              : Colors.black),
                    ),
                  )).toList(),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 10, spreadRadius: 2)
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _legendItem(Colors.green, 'Approved'),
                    _legendItem(Colors.orange, 'Pending'),
                    _legendItem(Colors.red, 'Rejected'),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              right: 16,
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: Colors.black),
                onPressed: () async {
                  if (_mapController != null && visits.isNotEmpty) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(
                          LatLng(visits.first.latitude, visits.first.longitude),
                          10),
                    );
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _legendItem(Color c, String label) {
    return Row(
      children: [
        Icon(Icons.location_on, color: c, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
