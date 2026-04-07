import 'dart:io';
import 'dart:typed_data';
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
import '../../services/cloudinary_service.dart';

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
  List<File> _additionalPhotos = [];
  Position? _position;
  String? _address;
  DateTime? _captureTime;
  double _progress = 0;
  bool _isFinal = false;
  bool _isLoading = false;
  String _status = '';
  bool _sigLocked = false;
  Uint8List? _sigImageBytes;

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
          _captureTime = DateTime.now();
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
      setState(() {
        if (_photo == null) {
          _photo = File(file.path);
        } else {
          _additionalPhotos.add(File(file.path));
        }
      });
    }
  }

  Future<void> _pickAdditionalPhoto() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 70);
    if (files.isNotEmpty) {
      setState(() {
        _additionalPhotos.addAll(files.map((f) => File(f.path)));
      });
    }
  }

  Future<void> _lockSignature() async {
    if (_sigCtrl.isEmpty) {
      _snack('Please sign before saving!', Colors.orange);
      return;
    }
    final bytes = await _sigCtrl.toPngBytes();
    if (bytes != null) {
      setState(() {
        _sigImageBytes = bytes;
        _sigLocked = true;
      });
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
    if (!_sigLocked) {
      _snack('Please lock your signature first!', Colors.orange);
      return;
    }

    final officer = Provider.of<AuthProvider>(context, listen: false).currentUser!;
    final visitProvider = Provider.of<VisitProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    // Save variables before popping
    final photoFile = _photo!;
    final sigBytes = _sigImageBytes!;
    final extraPhotos = List<File>.from(_additionalPhotos);
    final pos = _position!;
    final addr = _address;
    final capTime = _captureTime;
    final prog = _progress.toInt();
    final rem = _remarksCtrl.text.trim();
    final isFin = _isFinal;
    final tId = widget.task.id;
    final hodId = widget.task.createdBy;
    final reqTime = widget.task.lastVisitAt;

    setState(() {
      _isLoading = true;
      _status = 'Uploading assets...';
    });

    try {
      final List<Future<String?>> uploadFutures = [];

      uploadFutures.add(CloudinaryService().uploadImageToCloudinary(photoFile));
      uploadFutures.add(CloudinaryService().uploadBytesToCloudinary(
          sigBytes,
          'sig_${officer.employeeId}_${DateTime.now().millisecondsSinceEpoch}.png'));

      for (var file in _additionalPhotos) {
        uploadFutures.add(CloudinaryService().uploadImageToCloudinary(file));
      }

      final results = await Future.wait(uploadFutures);

      setState(() {
        _status = 'Saving record...';
      });

      final photoUrl = results[0];
      final sigUrl = results[1];
      final List<String> additionalUrls = [];
      for (int i = 2; i < results.length; i++) {
        if (results[i] != null) additionalUrls.add(results[i]!);
      }

      if (photoUrl == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Failed to upload primary photo. Check logs.'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
        return;
      }

      final visit = VisitModel(
        id: '',
        taskId: tId,
        officerId: officer.employeeId,
        photoUrl: photoUrl,
        additionalPhotos: additionalUrls,
        latitude: pos.latitude,
        longitude: pos.longitude,
        address: addr ?? '',
        gpsAccuracy: pos.accuracy,
        photoDateTime: capTime,
        progress: prog,
        remarks: rem,
        signatureUrl: sigUrl ?? '',
        isFinalVisit: isFin,
        department: officer.department,
        district: officer.district,
      );

      await visitProvider.submitVisit(
        visit: visit,
        hodId: hodId,
        lastVisitTime: reqTime,
      );

      messenger.showSnackBar(
        const SnackBar(
            content: Text('Visit report successfully submitted!'),
            backgroundColor: Colors.green),
      );
      nav.pop();
    } catch (e) {
      messenger.showSnackBar(
         SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
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
                        if (_captureTime != null)
                          Text(
                            'Captured at: ${_captureTime!.day}/${_captureTime!.month}/${_captureTime!.year} ${_captureTime!.hour}:${_captureTime!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900),
                          ),
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

            // Additional Photos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Additional Photos (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.add_a_photo_outlined),
                  onPressed: _pickAdditionalPhoto,
                ),
              ],
            ),
            if (_additionalPhotos.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _additionalPhotos.length,
                  itemBuilder: (ctx, i) => Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_additionalPhotos[i],
                              width: 100, height: 100, fit: BoxFit.cover),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () => setState(() => _additionalPhotos.removeAt(i)),
                            child: Container(
                              color: Colors.black.withOpacity(0.5),
                              child: const Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Officer Signature *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (!_sigLocked)
                  TextButton(
                    onPressed: () => _sigCtrl.clear(),
                    child: const Text('Clear', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: _sigLocked ? Colors.green : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: _sigLocked ? Colors.green.shade50 : Colors.grey.shade50,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _sigLocked
                    ? Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            Image.memory(_sigImageBytes!, height: 130),
                            const Text('Signature Saved & Locked',
                                style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                          ],
                        ),
                      )
                    : Signature(
                        controller: _sigCtrl,
                        height: 150,
                        backgroundColor: Colors.transparent,
                      ),
              ),
            ),
            if (!_sigLocked)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text('Save Signature'),
                    onPressed: _lockSignature,
                  ),
                ),
              ),
            if (_sigLocked)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text('Redo Signature'),
                  onPressed: () => setState(() {
                    _sigLocked = false;
                    _sigImageBytes = null;
                    _sigCtrl.clear();
                  }),
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
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(_status,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                        ],
                      )
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