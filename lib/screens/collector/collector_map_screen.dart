import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/visit_model.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';

class CollectorMapScreen extends StatefulWidget {
  const CollectorMapScreen({super.key});

  @override
  State<CollectorMapScreen> createState() => _CollectorMapScreenState();
}

class _CollectorMapScreenState extends State<CollectorMapScreen> {
  final MapController _mapController = MapController();
  String _deptFilter = 'All';
  VisitModel? _selectedVisit;
  Map<String, TaskModel> _tasksMap = {};
  Map<String, UserModel> _officersMap = {};
  bool _isLoadingExtraData = true;

  @override
  void initState() {
    super.initState();
    _fetchExtraData();
  }

  Future<void> _fetchExtraData() async {
    final district = context.read<AuthProvider>().currentUser?.district ?? '';
    if (district.isEmpty) return;

    try {
      // 1. Fetch Tasks
      final tasksStream = FirestoreService().getTasksByDistrict(district);
      final tasks = await tasksStream.first;
      
      // 2. Fetch Field Officers
      final officersStream = FirestoreService().getEmployeesStream(role: 'field_officer');
      final officers = await officersStream.first;

      if (mounted) {
        setState(() {
          _tasksMap = {for (var t in tasks) t.id: t};
          _officersMap = {for (var o in officers) o.employeeId: o};
          _isLoadingExtraData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingExtraData = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final district = context.watch<AuthProvider>().currentUser?.district ?? '';

    if (_isLoadingExtraData) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }

    return StreamBuilder<List<VisitModel>>(
      stream: FirestoreService().getVisitsByDistrict(district),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        }

        var visits = snap.data ?? [];
        if (_deptFilter != 'All') {
          visits = visits.where((v) => v.department == _deptFilter).toList();
        }

        List<Marker> markers = visits.map((v) {
          Color markerColor;
          if (v.status == 'approved') {
            markerColor = Colors.green;
          } else if (v.status == 'rejected') {
            markerColor = Colors.red;
          } else {
            markerColor = Colors.orange;
          }

          return Marker(
            point: LatLng(v.latitude, v.longitude),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedVisit = v);
                _mapController.move(LatLng(v.latitude, v.longitude), 12);
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                   Icon(Icons.location_on, color: markerColor, size: 40),
                   const Positioned(
                    top: 8,
                    child: Icon(Icons.circle, color: Colors.white, size: 10),
                   ),
                ],
              ),
            ),
          );
        }).toList();

        // District to Coordinates Mapping
        const districtCoordinates = {
          'Coimbatore': LatLng(11.0168, 76.9558),
          'Chennai': LatLng(13.0827, 80.2707),
          'Erode': LatLng(11.3410, 77.7172),
          'Salem': LatLng(11.6643, 78.1460),
        };

        debugPrint("Collector District: $district");
        debugPrint("Visits fetched: ${visits.length}");

        if (visits.isEmpty && _selectedVisit == null) {
          return const Center(child: Text('No data available in this district', style: TextStyle(color: Colors.grey)));
        }

        LatLng initialPos = districtCoordinates[district] ?? LatLng(11.1271, 78.6569);
        if (visits.isNotEmpty && _selectedVisit == null) {
          initialPos = LatLng(visits.first.latitude, visits.first.longitude);
        }

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: initialPos,
                zoom: 11,
                onTap: (_, __) => setState(() => _selectedVisit = null),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.inspetto.app',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
            
            // Top Filters
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
                      label: Text(dept, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      selected: _deptFilter == dept,
                      onSelected: (_) => setState(() {
                        _deptFilter = dept;
                        _selectedVisit = null;
                      }),
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

            // Legend
            Positioned(
              top: 80,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendItem(Colors.green, 'Approved'),
                    const SizedBox(height: 4),
                    _legendItem(Colors.orange, 'Pending'),
                    const SizedBox(height: 4),
                    _legendItem(Colors.red, 'Rejected'),
                  ],
                ),
              ),
            ),

            // Popup Info Card
            if (_selectedVisit != null)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: _buildVisitPopup(_selectedVisit!),
              ),

            // My Location Button
            Positioned(
              bottom: _selectedVisit != null ? 180 : 20,
              right: 20,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: Colors.black),
                onPressed: () {
                   if (visits.isNotEmpty) {
                    _mapController.move(
                      LatLng(visits.first.latitude, visits.first.longitude),
                      10,
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

  Widget _buildVisitPopup(VisitModel visit) {
    final task = _tasksMap[visit.taskId];
    final officer = _officersMap[visit.officerId];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task?.title ?? 'Unknown Task',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _selectedVisit = null),
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
          const Divider(),
          _infoRow(Icons.person, 'Officer', officer?.name ?? officer?.employeeId ?? 'Unknown'),
          _infoRow(Icons.info_outline, 'Status', visit.status.toUpperCase(), 
            color: visit.status == 'approved' ? Colors.green : (visit.status == 'rejected' ? Colors.red : Colors.orange)),
          _infoRow(Icons.trending_up, 'Progress', '${visit.progress}%'),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: visit.progress / 100,
            backgroundColor: Colors.grey[200],
            color: Colors.blue,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ],
      ),
    );
  }

  Widget _legendItem(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on, color: c, size: 14),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
