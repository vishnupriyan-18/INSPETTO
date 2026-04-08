import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/firebase_service.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();

  String _priority = 'medium';
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  String? _selectedOfficerId;
  List<UserModel> _officers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOfficers();
  }

  Future<void> _loadOfficers() async {
    final hodId = Provider.of<AuthProvider>(context, listen: false)
        .currentUser?.employeeId ?? '';
    FirestoreService().getEmployeesStream(role: 'field_officer', hodId: hodId)
        .listen((list) {
      if (mounted) setState(() => _officers = list);
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _purposeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.black),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOfficerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a field officer'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final hod = auth.currentUser!;

    final task = TaskModel(
      id: '',
      title: _titleCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      purpose: _purposeCtrl.text.trim(),
      priority: _priority,
      deadline: _deadline,
      assignedTo: _selectedOfficerId!,
      createdBy: hod.employeeId,
      status: 'assigned',
      department: hod.department,
      district: hod.district,
    );

    try {
      // Execute asynchronously to keep UI fast
      Provider.of<TaskProvider>(context, listen: false)
          .createTask(task, hod.employeeId);
          
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Task successfully created and assigned!'),
              backgroundColor: Colors.green),
        );
        _formKey.currentState?.reset();
        _titleCtrl.clear();
        _locationCtrl.clear();
        _purposeCtrl.clear();
        setState(() {
          _priority = 'medium';
          _selectedOfficerId = null;
          _deadline = DateTime.now().add(const Duration(days: 7));
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _isLoading = false);
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
            const Text('Create New Task',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _field('Task Title', _titleCtrl, 'Enter task title'),
            _field('Location', _locationCtrl, 'Site location'),
            _field('Purpose', _purposeCtrl, 'Describe the purpose'),
            // Priority
            const Text('Priority',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: ['high', 'medium', 'low'].map((p) {
                Color c = p == 'high'
                    ? Colors.red
                    : p == 'medium'
                        ? Colors.orange
                        : Colors.green;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = p),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _priority == p ? Colors.black : Colors.white,
                        border: Border.all(
                            color:
                                _priority == p ? Colors.black : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.circle, color: c, size: 12),
                          const SizedBox(height: 4),
                          Text(p.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: _priority == p
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Deadline
            const Text('Deadline',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDeadline,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      '${_deadline.day}/${_deadline.month}/${_deadline.year}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Assign Officer
            const Text('Assign To',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedOfficerId,
              hint: const Text('Select Field Officer'),
              items: _officers
                  .where((o) => o.isActive)
                  .map((o) => DropdownMenuItem(
                      value: o.employeeId,
                      child: Text('${o.name} (${o.employeeId})')))
                  .toList(),
              onChanged: (v) => setState(() => _selectedOfficerId = v),
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.black, width: 2)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
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
                    : const Text('Assign Task',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint) {
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
            decoration: InputDecoration(
              hintText: hint,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black, width: 2)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Required' : null,
          ),
        ],
      ),
    );
  }
}
