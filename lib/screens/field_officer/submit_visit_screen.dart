import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/task_model.dart';
import '../../models/visit_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/visit_provider.dart';
import '../../services/location_service.dart';
import '../../services/storage_service.dart';

class SubmitVisitScreen extends StatefulWidget {
  final TaskModel task;
  const SubmitVisitScreen({super.key, required this.task});

  @override
  State<SubmitVisitScreen> createState() => _SubmitVisitScreenState();
}

class _SubmitVisitScreenState extends State<SubmitVisitScreen> {
  final _remarksCtrl = TextEditingController();
  final _sigCtrl = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  File? _photo;
  Position? _position;
  String? _address;
  double _progress = 0;
  bool _isFinal = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _remarksCtrl.dispose();
    _sigCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    final pos = await LocationService().getCurrentPosition();
    if (pos != null) {
      final addr = await LocationService()
          .getAddressFromCoords(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _position = pos;
          _address = addr;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to get GPS location. Required to submit!'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (file != null) {
      setState(() => _photo = File(file.path));
    }
  }

  Future<void> _submit() async {
    if (_photo == null) {
      _snack('Photo is required!', Colors.red);
      return;
    }
    if (_position == null) {
      _snack('GPS location is required!', Colors.red);
      return;
    }
    if (_sigCtrl.isEmpty) {
      _snack('Signature is required!', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final officer =
          Provider.of<AuthProvider>(context, listen: false).currentUser!;
      final signatureBytes = await _sigCtrl.toPngBytes();

      // 1. Upload photo
      final photoUrl = await StorageService()
          .uploadVisitPhoto(widget.task.id, officer.employeeId, _photo!);

      // 2. Upload sig
      String sigUrl = '';
      if (signatureBytes != null) {
        sigUrl = await StorageService().uploadSignature(
            widget.task.id, officer.employeeId, signatureBytes);
      }

      // 3. Build model
      final visit = VisitModel(
        id: '',
        taskId: widget.task.id,
        officerId: officer.employeeId,
        photoUrl: photoUrl,
        latitude: _position!.latitude,
        longitude: _position!.longitude,
        address: _address ?? '',
        gpsAccuracy: _position!.accuracy,
        progress: _progress.toInt(),
        remarks: _remarksCtrl.text.trim(),
        signatureUrl: sigUrl,
        isFinalVisit: _isFinal,
        department: officer.department,
        district: officer.district,
      );

      // 4. Save
      await Provider.of<VisitProvider>(context, listen: false).submitVisit(
        visit: visit,
        hodId: widget.task.createdBy,
        lastVisitTime: widget.task.lastVisitAt,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Visit report submitted successfully!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context); // back to list
      }
    } catch (e) {
      _snack('Error: $e', Colors.red);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _snack(String msg, Color c) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: c));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Submit Visit',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Section
            const Text('Camera Capture *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _takePhoto,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _photo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_photo!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Tap to take photo',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // GPS Status
            const Text('Location Data *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _position != null
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _position != null
                        ? Colors.green.shade200
                        : Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                      _position != null
                          ? Icons.check_circle
                          : Icons.location_searching,
                      color: _position != null ? Colors.green : Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            _position != null
                                ? 'GPS Coordinates Locked'
                                : 'Fetching GPS...',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _position != null
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800)),
                        if (_position != null)
                          Text(
                              '${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}\nAccuracy: ${_position!.accuracy.toStringAsFixed(1)}m\n${_address ?? ''}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green.shade900)),
                      ],
                    ),
                  ),
                  if (_position == null)
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _fetchLocation,
                    )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Progress Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Work Progress (%)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${_progress.toInt()}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            Slider(
              value: _progress,
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: Colors.black,
              onChanged: (val) => setState(() => _progress = val),
            ),
            CheckboxListTile(
              title: const Text('Mark as Final Visit?'),
              value: _isFinal,
              activeColor: Colors.black,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (val) => setState(() => _isFinal = val ?? false),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),

            // Remarks
            const Text('Remarks',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _remarksCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add any observation notes...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.black)),
              ),
            ),
            const SizedBox(height: 24),

            // Signature
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Officer Signature *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton(
                  onPressed: () => _sigCtrl.clear(),
                  child: const Text('Clear', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Signature(
                  controller: _sigCtrl,
                  height: 150,
                  backgroundColor: Colors.grey.shade50,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Visit Report',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}