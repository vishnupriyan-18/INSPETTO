// HOD creates a new inspection task
// Member 3 implements this
import 'package:flutter/material.dart';

class CreateTaskScreen extends StatelessWidget {
  const CreateTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement form
    // Fields: Task title, Location, Purpose, Priority dropdown, Deadline date picker
    // Assign to: dropdown of field officers
    // Submit button -> saves to Firebase -> sends notification to officer
    return const Scaffold(body: Center(child: Text('Create Task')));
  }
}
