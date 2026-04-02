import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../models/visit_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/visit_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/status_badge.dart';

class HodReviewScreen extends StatelessWidget {
  final TaskModel task;
  const HodReviewScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(task.title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis),
      ),
      body: StreamBuilder<List<VisitModel>>(
        stream: FirestoreService().getVisitsForTask(task.id),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.black));
          }
          final visits = snap.data ?? [];
          if (visits.isEmpty) {
            return const Center(
                child: Text('No visit reports submitted yet.',
                    style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: visits.length,
            itemBuilder: (ctx, i) =>
                _VisitCard(visit: visits[i], task: task),
          );
        },
      ),
    );
  }
}

class _VisitCard extends StatefulWidget {
  final VisitModel visit;
  final TaskModel task;
  const _VisitCard({required this.visit, required this.task});

  @override
  State<_VisitCard> createState() => _VisitCardState();
}

class _VisitCardState extends State<_VisitCard> {
  bool _expanded = false;
  bool _isProcessing = false;

  Future<void> _approve() async {
    setState(() => _isProcessing = true);
    final hodId = Provider.of<AuthProvider>(context, listen: false)
        .currentUser?.employeeId ?? '';
    await Provider.of<VisitProvider>(context, listen: false).approveVisit(
      visitId: widget.visit.id,
      taskId: widget.task.id,
      officerId: widget.visit.officerId,
      hodId: hodId,
      remarks: 'Approved by HOD',
    );
    setState(() => _isProcessing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit approved!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _reject() async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Visit'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
              hintText: 'Enter rejection reason',
              border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reject',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true || reasonCtrl.text.isEmpty) return;

    setState(() => _isProcessing = true);
    final hodId = Provider.of<AuthProvider>(context, listen: false)
        .currentUser?.employeeId ?? '';
    await Provider.of<VisitProvider>(context, listen: false).rejectVisit(
      visitId: widget.visit.id,
      taskId: widget.task.id,
      officerId: widget.visit.officerId,
      hodId: hodId,
      reason: reasonCtrl.text.trim(),
    );
    setState(() => _isProcessing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit rejected'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.visit;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: v.isSuspicious ? Colors.orange.shade200 : Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Visit Report',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                StatusBadge(status: v.status),
              ],
            ),
            if (v.isSuspicious)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                    SizedBox(width: 6),
                    Text('⚠ Suspicious Submission',
                        style:
                            TextStyle(color: Colors.orange, fontSize: 12)),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            // Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Progress', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text('${v.progress}%', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: v.progress / 100,
              backgroundColor: Colors.grey.shade200,
              color: Colors.black,
            ),
            const SizedBox(height: 12),
            // GPS
            _infoRow(Icons.location_on_outlined,
                '${v.latitude.toStringAsFixed(5)}, ${v.longitude.toStringAsFixed(5)}\n${v.address}'),
            _infoRow(Icons.gps_fixed,
                'Accuracy: ${v.gpsAccuracy.toStringAsFixed(1)} m'),
            // Remarks
            if (v.remarks.isNotEmpty)
              _infoRow(Icons.notes_outlined, v.remarks),
            // Rejection reason
            if (v.rejectionReason.isNotEmpty)
              _infoRow(Icons.cancel_outlined, 'Rejected: ${v.rejectionReason}',
                  color: Colors.red),
            // Photo
            if (v.photoUrl.isNotEmpty) ...[
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200)),
                  clipBehavior: Clip.hardEdge,
                  child: Image.network(
                    v.photoUrl,
                    height: _expanded ? 300 : 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Center(child: Icon(Icons.broken_image)),
                  ),
                ),
              ),
            ],
            // Signature
            if (v.signatureUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Signature',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 4),
              Image.network(v.signatureUrl, height: 60,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ],
            // Approve/Reject buttons (only if pending)
            if (v.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red)),
                      onPressed: _isProcessing ? null : _reject,
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black),
                      onPressed: _isProcessing ? null : _approve,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Approve',
                              style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12, color: color ?? Colors.black87)),
          ),
        ],
      ),
    );
  }
}
