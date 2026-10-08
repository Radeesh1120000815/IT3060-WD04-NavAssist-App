import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/emergency_contact.dart';
import 'data/emergency_contact_repository.dart';
import 'widgets/safety_widgets.dart';

class AddEmergencyContactScreen extends StatefulWidget {
  const AddEmergencyContactScreen({super.key, this.repository, this.contact});

  final EmergencyContactDataSource? repository;
  final EmergencyContact? contact;

  @override
  State<AddEmergencyContactScreen> createState() =>
      _AddEmergencyContactScreenState();
}

class _AddEmergencyContactScreenState extends State<AddEmergencyContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _customRelationshipController = TextEditingController();
  final _phoneController = TextEditingController();
  late final EmergencyContactDataSource _repository;
  bool _isSaving = false;
  String? _selectedRelationship;

  static const relationshipOptions = [
    'Mother',
    'Father',
    'Sister',
    'Brother',
    'Spouse',
    'Son',
    'Daughter',
    'Friend',
    'Caregiver',
    'Guardian',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? EmergencyContactRepository();
    final contact = widget.contact;
    if (contact != null) {
      _nameController.text = contact.name;
      _phoneController.text = contact.phone;
      if (relationshipOptions.contains(contact.relationship)) {
        _selectedRelationship = contact.relationship;
      } else {
        _selectedRelationship = 'Other';
        _customRelationshipController.text = contact.relationship;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _customRelationshipController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  String? _validatePhone(String? value) {
    final requiredError = _required(value, 'Phone number');
    if (requiredError != null) return requiredError;
    final normalized = value!.replaceAll(RegExp(r'[\s()+-]'), '');
    if (!RegExp(r'^\d{7,15}$').hasMatch(normalized)) {
      return 'Enter a valid phone number using 7 to 15 digits.';
    }
    return null;
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final relationship = _selectedRelationship == 'Other'
          ? _customRelationshipController.text.trim()
          : _selectedRelationship!;
      if (widget.contact == null) {
        await _repository.createEmergencyContact(
          name: _nameController.text,
          relationship: relationship,
          phone: _phoneController.text,
        );
      } else {
        await _repository.updateEmergencyContact(
          contactId: widget.contact!.id,
          name: _nameController.text,
          relationship: relationship,
          phone: _phoneController.text,
        );
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline, size: 40),
          title: Text(
            widget.contact == null
                ? 'Contact added successfully'
                : 'Contact updated successfully',
          ),
          content: Text(
            widget.contact == null
                ? '${_nameController.text.trim()} is now a saved emergency contact.'
                : '${_nameController.text.trim()} was updated successfully.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) context.pop();
    } on Object catch (error) {
      if (!mounted) return;
      final message = emergencyContactErrorMessage(error, operation: 'save');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.contact == null
              ? 'Add emergency contact'
              : 'Edit emergency contact',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const DemoDataBanner(
              message: 'This contact will support the SOS prototype. No call or message will be sent.',
            ),
            const SizedBox(height: 20),
            const SafetySectionTitle('Contact details'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Maya Perera',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => _required(value, 'Name'),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: _selectedRelationship == null
                  ? 'Relationship, not selected'
                  : 'Relationship, $_selectedRelationship, selected',
              child: DropdownButtonFormField<String>(
                initialValue: _selectedRelationship,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  prefixIcon: Icon(Icons.people_outline),
                  helperText: 'Select how this person is related to you',
                ),
                hint: const Text('Select relationship'),
                items: [
                  for (final option in relationshipOptions)
                    DropdownMenuItem(value: option, child: Text(option)),
                ],
                onChanged: _isSaving
                    ? null
                    : (value) => setState(() {
                        _selectedRelationship = value;
                        _relationshipController.text = value ?? '';
                      }),
                validator: (_) => _selectedRelationship == null
                    ? 'Relationship is required.'
                    : null,
              ),
            ),
            if (_selectedRelationship == 'Other') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _customRelationshipController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Custom relationship',
                  hintText: 'For example, neighbour',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
                validator: (value) => _required(value, 'Custom relationship'),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: '0771234567',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: _validatePhone,
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add_outlined),
              label: Text(
                _isSaving
                    ? 'Saving contact...'
                    : widget.contact == null
                    ? 'Save contact'
                    : 'Save changes',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
