import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:signature/signature.dart';
import 'package:inspetto/themes/app_colors.dart';

class SubmitVisitScreen extends StatefulWidget {
  final String taskId;
  const SubmitVisitScreen({super.key, required this.taskId});

  @override
  State<SubmitVisitScreen> createState() => _SubmitVisitScreenState();
}

class _SubmitVisitScreenState extends State<SubmitVisitScreen> {
  final TextEditingController _remarksController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  double _progress = 0;
  bool _isFinalVisit = false;
  bool _isLoading = false;
  bool _locationLoading = true;
  File? _photo;
  Uint8List? _signature;
  double _latitude = 0.0;
  double _longitude = 0.0;
  String _gpsLocation = 'Fetching location...';
  String _photoDateTime = '';
  List<File> _additionalFiles = [];

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  void _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _gpsLocation = 'Location permission denied';
            _locationLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _gpsLocation = 'Location permission permanently denied';
          _locationLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _gpsLocation =
              '${position.latitude.toStringAsFixed(4)}° N, '
              '${position.longitude.toStringAsFixed(4)}° E'
              ' — ${place.street}, ${place.locality}';
          _locationLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _gpsLocation = 'Error getting location';
        _locationLoading = false;
      });
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (file != null) {
      final now = DateTime.now();
      setState(() {
        _photo = File(file.path);
        _photoDateTime =
            '${now.day.toString().padLeft(2, '0')}/'
            '${now.month.toString().padLeft(2, '0')}/'
            '${now.year}  '
            '${now.hour.toString().padLeft(2, '0')}:'
            '${now.minute.toString().padLeft(2, '0')}:'
            '${now.second.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickAdditionalFile() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Attachment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.black,
                child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final file = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (file != null) {
                  setState(() => _additionalFiles.add(File(file.path)));
                }
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.black,
                child: Icon(Icons.photo_library,
                    color: Colors.white, size: 20),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final file = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (file != null) {
                  setState(() => _additionalFiles.add(File(file.path)));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSignature() async {
    final sig = await _signatureController.toPngBytes();
    if (sig != null) {
      setState(() => _signature = sig);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signature saved!'),
          backgroundColor: Colors.black,
        ),
      );
    }
  }

  Future<bool> _authenticateWithBiometric() async {
    try {
      final bool canAuthenticate = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric not available on this device!'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to submit visit report',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      return authenticated;
    } catch (e) {
      print('Biometric error: $e');
      return false;
    }
  }

  void _submitVisit() async {
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take a photo!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_signature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add your signature!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_remarksController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add remarks!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_latitude == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for GPS location!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bool authenticated = await _authenticateWithBiometric();
    if (!authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication failed! Cannot submit report.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Upload photo to Firebase Storage
    // TODO: Save visit data to Firestore
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Visit report submitted successfully!'),
        backgroundColor: Colors.black,
      ),
    );

    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Submit Visit Report'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── PHOTO SECTION ──
            const Text('Photo Proof',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _takePhoto,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _photo != null
                        ? Colors.black
                        : AppColors.border,
                    width: _photo != null ? 2 : 1,
                  ),
                ),
                child: _photo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_photo!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              size: 50, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Tap to take photo',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // ── GPS + DATE TIME SECTION ──
            const Text('GPS Location',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _latitude != 0.0
                      ? Colors.black
                      : AppColors.border,
                  width: _latitude != 0.0 ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _locationLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black),
                            )
                          : Icon(
                              _latitude != 0.0
                                  ? Icons.location_on
                                  : Icons.location_off,
                              color: _latitude != 0.0
                                  ? Colors.black
                                  : Colors.red,
                              size: 20,
                            ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _gpsLocation,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      if (_latitude != 0.0)
                        const Icon(Icons.check_circle,
                            color: AppColors.approved, size: 16),
                    ],
                  ),
                  // Date and time — shows when photo is taken
                  if (_photoDateTime.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          _photoDateTime,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── PROGRESS SECTION ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Work Progress',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                Text(
                  '${_progress.toInt()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.black,
                inactiveTrackColor: AppColors.border,
                thumbColor: Colors.black,
                overlayColor: Colors.black.withOpacity(0.1),
              ),
              child: Slider(
                value: _progress,
                min: 0,
                max: 100,
                divisions: 10,
                onChanged: (value) =>
                    setState(() => _progress = value),
              ),
            ),
            const SizedBox(height: 20),

            // ── REMARKS + ADD FILE SECTION ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Observations / Remarks',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: _pickAdditionalFile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Add File',
                          style: TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _remarksController,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText:
                    'Enter your observations about this visit...',
                hintStyle:
                    const TextStyle(color: AppColors.textHint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Colors.black, width: 2),
                ),
              ),
            ),

            // Additional files thumbnails
            if (_additionalFiles.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Attachments',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _additionalFiles.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _additionalFiles[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(
                                () => _additionalFiles.removeAt(index)),
                            child: const CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close,
                                  size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),

            // ── SIGNATURE SECTION ──
            const Text('Digital Signature',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Signature(
                controller: _signatureController,
                height: 120,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      _signatureController.clear();
                      setState(() => _signature = null);
                    },
                    child: const Text('Clear',
                        style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _saveSignature,
                    child: const Text('Save Signature',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),

            if (_signature != null) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.check_circle,
                      color: AppColors.approved, size: 16),
                  SizedBox(width: 4),
                  Text('Signature saved!',
                      style: TextStyle(
                          color: AppColors.approved, fontSize: 12)),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // ── FINAL VISIT TOGGLE ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mark as Final Visit',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                      Text('Work is 100% complete',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  Switch(
                    value: _isFinalVisit,
                    onChanged: (value) =>
                        setState(() => _isFinalVisit = value),
                    activeColor: Colors.black,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // ── SUBMIT BUTTON ──
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _submitVisit,
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : const Text(
                        'Submit Visit Report',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}