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

        // ── CALCULATE LATEST VISITS PER TASK ──
        final Map<String, List<VisitModel>> visitsByTask = {};
        for (var v in visits) {
          visitsByTask.putIfAbsent(v.taskId, () => []).add(v);
        }
        
        final List<VisitModel> latestVisits = [];
        for (var tId in visitsByTask.keys) {
          final sorted = List<VisitModel>.from(visitsByTask[tId]!);
          sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          latestVisits.add(sorted.first);
        }

        List<Marker> markers = latestVisits.map((v) {
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
                child: _buildVisitPopup(_selectedVisit!, visits),
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

  Widget _buildVisitPopup(VisitModel visit, List<VisitModel> allVisits) {
    final task = _tasksMap[visit.taskId];
    final officer = _officersMap[visit.officerId];
    
    final taskVisits = allVisits.where((v) => v.taskId == visit.taskId).toList();

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
          _infoRow(Icons.info_outline, 'Latest Status', visit.status.toUpperCase(), 
            color: visit.status == 'approved' ? Colors.green : (visit.status == 'rejected' ? Colors.red : Colors.orange)),
          _infoRow(Icons.trending_up, 'Latest Progress', '${visit.progress}%'),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: visit.progress / 100,
            backgroundColor: Colors.grey[200],
            color: Colors.blue,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.list_alt, size: 18),
              label: const Text('View All Reports'),
              onPressed: () => _showReportsList(context, taskVisits, task, officer),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportsList(BuildContext context, List<VisitModel> taskVisits, TaskModel? task, UserModel? officer) {
    taskVisits.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (ctx, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(task?.title ?? 'Task Reports', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Divider(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: taskVisits.length,
                  itemBuilder: (context, index) {
                    final visit = taskVisits[index];
                    final reportNum = index + 1;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        onTap: () {
                          // Allow viewing report directly over the current bottom sheet
                          _showFullReport(context, visit, task, officer, reportNum);
                        },
                        title: Text('Report $reportNum', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${visit.progress}% Progress'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: visit.status == 'approved' ? Colors.green.shade50 : visit.status == 'rejected' ? Colors.red.shade50 : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: visit.status == 'approved' ? Colors.green : visit.status == 'rejected' ? Colors.red : Colors.orange),
                          ),
                          child: Text(visit.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: visit.status == 'approved' ? Colors.green : visit.status == 'rejected' ? Colors.red : Colors.orange)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullReport(BuildContext context, VisitModel visit, TaskModel? task, UserModel? officer, int reportNum) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (ctx, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Text(
                'Report $reportNum - ${task?.title ?? 'Visit'}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 4),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: visit.status == 'approved'
                      ? Colors.green.shade50
                      : visit.status == 'rejected'
                          ? Colors.red.shade50
                          : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: visit.status == 'approved'
                        ? Colors.green
                        : visit.status == 'rejected'
                            ? Colors.red
                            : Colors.orange,
                  ),
                ),
                child: Text(
                  visit.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: visit.status == 'approved'
                        ? Colors.green
                        : visit.status == 'rejected'
                            ? Colors.red
                            : Colors.orange,
                  ),
                ),
              ),
              const Divider(height: 24),
              // Photo (Interactive Reveal)
              const Text('Site Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (ctx, setInternalState) {
                  bool showPhoto = false;
                  return GestureDetector(
                    onTap: () => setInternalState(() => showPhoto = true),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: !showPhoto 
                        ? Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_outlined, color: Colors.grey, size: 30),
                                SizedBox(height: 8),
                                Text('Tap to View Site Photo', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        : visit.photoUrl == 'uploading' || visit.photoUrl.isEmpty
                            ? Container(
                                height: 160,
                                color: Colors.grey.shade100,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(strokeWidth: 2),
                                    SizedBox(height: 8),
                                    Text('Photo uploading...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              )
                            : Image.network(
                                visit.photoUrl,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
                              ),
                    ),
                  );
                }
              ),
              const SizedBox(height: 16),
              // Info rows
              _reportRow(Icons.person, 'Officer', officer?.name ?? visit.officerId),
              _reportRow(Icons.business, 'Department', visit.department),
              _reportRow(Icons.location_on_outlined, 'Address', visit.address.isNotEmpty ? visit.address : '${visit.latitude.toStringAsFixed(5)}, ${visit.longitude.toStringAsFixed(5)}'),
              _reportRow(Icons.gps_fixed, 'GPS Accuracy', '${visit.gpsAccuracy.toStringAsFixed(1)} m'),
              _reportRow(Icons.trending_up, 'Progress', '${visit.progress}%'),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: visit.progress / 100,
                backgroundColor: Colors.grey.shade200,
                color: Colors.blue,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              if (visit.remarks.isNotEmpty) ...[
                const SizedBox(height: 12),
                _reportRow(Icons.notes, 'Remarks', visit.remarks),
              ],
              if (visit.isFinalVisit) ...[
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 6),
                    Text('Final Visit', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
