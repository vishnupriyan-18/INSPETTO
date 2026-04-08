import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    _progress = widget.task.progress.toDouble();
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

    // --- AUTHENTICATION CHECK ---
    final LocalAuthentication auth = LocalAuthentication();
    bool isAuthenticated = false;

    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (canAuthenticate) {
        isAuthenticated = await auth.authenticate(
          localizedReason: 'Please authenticate to submit your visit report',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );

        if (!isAuthenticated) {
          _snack('Authentication required to submit', Colors.red);
          return;
        }
      } else {
        isAuthenticated = await _fallbackToOTP();
        if (!isAuthenticated) return;
      }
    } on PlatformException catch (e) {
      if (e.code == 'NotEnrolled' ||
          e.code == 'PasscodeNotSet' ||
          e.code == 'DeviceCredentialsNotEnrolled') {
        isAuthenticated = await _fallbackToOTP();
        if (!isAuthenticated) return;
      } else {
        _snack('Authentication error: ${e.message}', Colors.red);
        return;
      }
    } catch (e) {
      isAuthenticated = await _fallbackToOTP();
      if (!isAuthenticated) return;
    }
    // --- END AUTHENTICATION CHECK ---

    final officer = Provider.of<AuthProvider>(context, listen: false).currentUser!;
    final visitProvider = Provider.of<VisitProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    // Capture all values before async gap
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
    final employeeId = officer.employeeId;
    final department = officer.department;
    final district = officer.district;

    setState(() {
      _isLoading = true;
      _status = 'Saving record...';
    });

    try {
      // ── STEP 1: Write to Firestore immediately with placeholder URLs ──
      // Image URLs will be patched in background after upload completes.
      final visit = VisitModel(
        id: '',
        taskId: tId,
        officerId: employeeId,
        photoUrl: 'uploading',        // placeholder
        additionalPhotos: const [],
        latitude: pos.latitude,
        longitude: pos.longitude,
        address: addr ?? '',
        gpsAccuracy: pos.accuracy,
        photoDateTime: capTime,
        progress: prog,
        remarks: rem,
        signatureUrl: 'uploading',    // placeholder
        isFinalVisit: isFin,
        department: department,
        district: district,
      );

      // This writes to Firestore (batch: visit + task update + notification + log)
      final visitId = await visitProvider.submitVisit(
        visit: visit,
        hodId: hodId,
        lastVisitTime: reqTime,
      );

      // ── STEP 2: Show success and navigate back immediately ──
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Visit report submitted! Photos uploading in background…'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4)),
      );
      nav.pop();

      // ── STEP 3: Upload to Cloudinary in the background ──
      // No await here — fire and forget. Updates Firestore when done.
      _uploadAndPatchVisit(
        visitId: visitId,
        photoFile: photoFile,
        sigBytes: sigBytes,
        sigFileName: 'sig_${employeeId}_${DateTime.now().millisecondsSinceEpoch}.png',
        extraPhotos: extraPhotos,
      );
    } catch (e) {
      messenger.showSnackBar(
         SnackBar(content: Text('Submit failed: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  /// Runs in background after the screen is already gone.
  /// Uploads all media to Cloudinary and patches the Firestore visit document.
  void _uploadAndPatchVisit({
    required String visitId,
    required File photoFile,
    required Uint8List sigBytes,
    required String sigFileName,
    required List<File> extraPhotos,
  }) {
    Future(() async {
      try {
        final cs = CloudinaryService();
        // Upload primary photo + signature in parallel
        final mainResults = await Future.wait([
          cs.uploadImageToCloudinary(photoFile),
          cs.uploadBytesToCloudinary(sigBytes, sigFileName),
        ]);

        final photoUrl = mainResults[0] ?? '';
        final sigUrl = mainResults[1] ?? '';

        // Upload extra photos
        final extraUrls = <String>[];
        for (final f in extraPhotos) {
          final url = await cs.uploadImageToCloudinary(f);
          if (url != null) extraUrls.add(url);
        }

        // Patch the Firestore document with real URLs
        if (visitId.isNotEmpty) {
          await FirebaseFirestore.instance.collection('visits').doc(visitId).update({
            'photoUrl': photoUrl,
            'signatureUrl': sigUrl,
            'additionalPhotos': extraUrls,
          });
        }
        debugPrint('Background upload complete for visit $visitId');
      } catch (e) {
        debugPrint('Background upload error for visit $visitId: $e');
      }
    });
  }

  Future<bool> _fallbackToOTP() async {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final officerId = authProv.currentUser!.employeeId;

    _snack('No device lock detected. Verifying via OTP...', Colors.blue);
    setState(() => _isLoading = true);

    final user = await authProv.getEmployeeDetails(officerId);
    setState(() => _isLoading = false);

    if (user == null || user.phone.isEmpty) {
      _snack('No phone number registered for OTP fallack.', Colors.red);
      return false;
    }

    setState(() => _isLoading = true);
    final error = await authProv.sendOTP(user.phone);
    setState(() => _isLoading = false);

    if (error != null) {
      _snack(error, Colors.red);
      return false;
    }

    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _OTPDialog(phone: user.phone),
    );

    return result ?? false;
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

class _OTPDialog extends StatefulWidget {
  final String phone;
  const _OTPDialog({required this.phone});

  @override
  State<_OTPDialog> createState() => _OTPDialogState();
}

class _OTPDialogState extends State<_OTPDialog> {
  final TextEditingController _otpCtrl = TextEditingController();
  bool _isVerifying = false;

  Future<void> _verify() async {
    if (_otpCtrl.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter 6-digit OTP'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isVerifying = true);
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProv.verifyOTP(_otpCtrl.text.trim());
    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP. Please try again.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('OTP Verification', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enter the 6-digit code sent to +91 ${widget.phone}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 20),
          PinCodeTextField(
            appContext: context,
            length: 6,
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(8),
              fieldHeight: 45,
              fieldWidth: 35,
              activeColor: Colors.black,
              selectedColor: Colors.black,
              inactiveColor: Colors.grey.shade300,
            ),
            onChanged: (val) {},
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isVerifying ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
          onPressed: _isVerifying ? null : _verify,
          child: _isVerifying 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
              : const Text('Verify'),
        ),
      ],
    );
  }
}