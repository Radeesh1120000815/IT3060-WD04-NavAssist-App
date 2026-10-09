import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/emergency_contact.dart';
import 'data/emergency_contact_repository.dart';
import 'widgets/safety_widgets.dart';

class AddEmergencyContactScreen extends StatefulWidget {
  const AddEmergencyContactScreen({
    super.key,
    this.repository,
    this.contactId,
    this.contact,
  });

  final EmergencyContactDataSource? repository;
  final String? contactId;
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
  EmergencyContact? _contact;
  bool _isLoadingContact = false;
  bool _contactNotFound = false;
  String? _loadError;
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
    _contact = widget.contact;
    if (_contact case final contact?) {
      _fillForm(contact);
    } else if (widget.contactId != null) {
      _loadContact();
    }
  }

  bool get _isEditMode => widget.contact != null || widget.contactId != null;

  void _fillForm(EmergencyContact contact) {
    _nameController.text = contact.name;
    _phoneController.text = contact.phone;
    if (relationshipOptions.contains(contact.relationship)) {
      _selectedRelationship = contact.relationship;
      _relationshipController.text = contact.relationship;
    } else {
      _selectedRelationship = 'Other';
      _relationshipController.text = 'Other';
      _customRelationshipController.text = contact.relationship;
    }
  }

  Future<void> _loadContact() async {
    final contactId = widget.contactId;
    if (contactId == null) return;

    setState(() {
      _isLoadingContact = true;
      _contactNotFound = false;
      _loadError = null;
    });
    try {
      final contact = await _repository.getEmergencyContact(contactId);
      if (!mounted) return;
      if (contact == null) {
        setState(() {
          _isLoadingContact = false;
          _contactNotFound = true;
        });
        return;
      }
      _fillForm(contact);
      setState(() {
        _contact = contact;
        _isLoadingContact = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingContact = false;
        _loadError = emergencyContactErrorMessage(error, operation: 'load');
      });
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
      if (!_isEditMode) {
        await _repository.createEmergencyContact(
          name: _nameController.text,
          relationship: relationship,
          phone: _phoneController.text,
        );
      } else {
        await _repository.updateEmergencyContact(
          contactId: widget.contactId ?? _contact!.id,
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
            !_isEditMode
                ? 'Contact added successfully'
                : 'Contact updated successfully',
          ),
          content: Text(
            !_isEditMode
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
          !_isEditMode ? 'Add emergency contact' : 'Edit emergency contact',
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingContact) {
      return Center(
        child: Semantics(
          label: 'Loading emergency contact',
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading emergency contact...'),
            ],
          ),
        ),
      );
    }

    if (_contactNotFound) {
      return const _ContactLoadState(
        icon: Icons.person_off_outlined,
        title: 'Contact not found',
        message: 'This emergency contact may have been deleted.',
      );
    }

    if (_loadError case final message?) {
      return _ContactLoadState(
        icon: Icons.error_outline,
        title: 'Could not load emergency contact',
        message: message,
        actionLabel: 'Retry',
        onAction: _loadContact,
      );
    }

    return Form(
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
                  : !_isEditMode
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
    );
  }
}

class _ContactLoadState extends StatelessWidget {
  const _ContactLoadState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          container: true,
          label: '$title. $message',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(child: Icon(icon, size: 48)),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
