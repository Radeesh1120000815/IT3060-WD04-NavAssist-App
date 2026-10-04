import 'package:flutter/material.dart';

class ReportHazardScreen extends StatefulWidget {
  const ReportHazardScreen({super.key});

  @override
  State<ReportHazardScreen> createState() => _ReportHazardScreenState();
}

class _ReportHazardScreenState extends State<ReportHazardScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _type;
  String? _severity;

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'Please enter $label.';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Form is valid. Saving will be added in the Firestore phase.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report a hazard')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Required fields are marked with an asterisk. This prototype validates the form but does not save reports.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Hazard type *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Broken pavement',
                  child: Text('Broken pavement'),
                ),
                DropdownMenuItem(
                  value: 'Obstruction',
                  child: Text('Obstruction'),
                ),
                DropdownMenuItem(
                  value: 'Unsafe crossing',
                  child: Text('Unsafe crossing'),
                ),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => _type = value),
              validator: (value) =>
                  value == null ? 'Please select a hazard type.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Describe what makes the area difficult or unsafe',
                border: OutlineInputBorder(),
              ),
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) => _required(value, 'a hazard description'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Location *',
                hintText: 'Street, stop, or nearby place',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) => _required(value, 'the hazard location'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _severity,
              decoration: const InputDecoration(
                labelText: 'Severity *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Low', child: Text('Low — take care')),
                DropdownMenuItem(
                  value: 'Medium',
                  child: Text('Medium — route partly affected'),
                ),
                DropdownMenuItem(
                  value: 'High',
                  child: Text('High — route may be unsafe'),
                ),
              ],
              onChanged: (value) => setState(() => _severity = value),
              validator: (value) =>
                  value == null ? 'Please select a severity.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Landmark or reference point (optional)',
                hintText: 'For example, beside the library entrance',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            Semantics(
              button: true,
              label: 'Validate hazard report form',
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.send_outlined),
                label: const Text('Submit report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
