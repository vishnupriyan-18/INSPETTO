// Screen where officer submits inspection report
// Member 2 implements this - MOST IMPORTANT SCREEN
import 'package:flutter/material.dart';

class SubmitVisitScreen extends StatelessWidget {
  final String taskId;
  const SubmitVisitScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    // TODO: implement
    // 1. Camera capture (live photo only)
    // 2. GPS auto-capture (shown to user, not editable)
    // 3. Remarks text field
    // 4. Progress % slider (0 to 100)
    // 5. Is this final visit? Yes/No toggle
    // 6. Digital signature pad
    // 7. Submit button with OTP or fingerprint verification
    return const Scaffold(body: Center(child: Text('Submit Visit')));
  }
}
