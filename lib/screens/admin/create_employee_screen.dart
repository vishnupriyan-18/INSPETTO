import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';

class CreateEmployeeScreen extends StatefulWidget {
  const CreateEmployeeScreen({super.key});

  @override
  State<CreateEmployeeScreen> createState() => _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState extends State<CreateEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _empIdCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _hodIdCtrl = TextEditingController();

  String _role = 'field_officer';
  String _department = 'TNRD';
  String _district = 'Coimbatore';
  bool _isLoading = false;

  final _roles = ['hod', 'field_officer', 'collector'];
  final _departments = ['TNRD', 'TWAD', 'Highways', 'Municipality', 'Corporation'];
  final _districts = ['Coimbatore', 'Chennai', 'Erode', 'Salem'];

  @override
  void dispose() {
    _empIdCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _hodIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String designation = '';
    if (_role == 'it_admin') designation = 'IT Administrator';
    else if (_role == 'hod') designation = 'Head of Department';
    else if (_role == 'field_officer') designation = 'Field Officer';
    else if (_role == 'collector') designation = 'District Collector';

    final user = UserModel(
      employeeId: _empIdCtrl.text.trim().toUpperCase(),
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      role: _role,
      designation: designation,
      department: _department,
      district: _district,
      hodId: _role == 'field_officer' ? _hodIdCtrl.text.trim().toUpperCase() : '',
      isActive: true,
      createdByAdmin: true,
    );

    try {
      await FirestoreService().createEmployee(user);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Employee created successfully'),
              backgroundColor: Colors.green),
        );
        _formKey.currentState?.reset();
        _empIdCtrl.clear();
        _nameCtrl.clear();
        _phoneCtrl.clear();
        _hodIdCtrl.clear();
        setState(() => _role = 'field_officer');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create Employee',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _field('Employee ID', _empIdCtrl, hint: 'e.g. EMP001',
                caps: TextCapitalization.characters),
            _field('Full Name', _nameCtrl, hint: 'Enter full name'),
            _field('Phone Number', _phoneCtrl,
                hint: '10-digit mobile', keyboard: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length != 10) return 'Enter 10-digit number';
                  return null;
                }),
            _dropdown('Role', _roles, _role, (v) => setState(() => _role = v!)),
            _dropdown('Department', _departments, _department,
                (v) => setState(() => _department = v!)),
            _dropdown('District', _districts, _district,
                (v) => setState(() => _district = v!)),
            if (_role == 'field_officer') ...[
              const SizedBox(height: 8),
              _field('HOD Employee ID', _hodIdCtrl,
                  hint: 'HOD\'s Employee ID',
                  caps: TextCapitalization.characters,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'HOD ID required for FO' : null),
            ],
            const SizedBox(height: 24),
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
                    : const Text('Create Employee',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {String hint = '',
      TextInputType keyboard = TextInputType.text,
      TextCapitalization caps = TextCapitalization.words,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            keyboardType: keyboard,
            textCapitalization: caps,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black, width: 2)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            validator:
                validator ?? (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String label, List<String> items, String val,
      void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: val,
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black, width: 2)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
