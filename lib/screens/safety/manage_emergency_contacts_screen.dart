import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../voice/services/haptic_service.dart';
import 'data/emergency_contact.dart';
import 'data/emergency_contact_repository.dart';
import 'safety_routes.dart';

class ManageEmergencyContactsScreen extends StatefulWidget {
  const ManageEmergencyContactsScreen({super.key, this.repository});

  final EmergencyContactDataSource? repository;

  @override
  State<ManageEmergencyContactsScreen> createState() =>
      _ManageEmergencyContactsScreenState();
}

class _ManageEmergencyContactsScreenState
    extends State<ManageEmergencyContactsScreen> {
  late final EmergencyContactDataSource _repository;
  late Stream<List<EmergencyContact>> _contacts;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? EmergencyContactRepository();
    _contacts = _repository.streamEmergencyContacts();
  }

  void _retry() {
    setState(() => _contacts = _repository.streamEmergencyContacts());
  }

  Future<void> _setPrimary(EmergencyContact contact) async {
    try {
      await _repository.setPrimaryContact(contact.id);
      if (!mounted) return;
      await context.read<HapticService?>()?.vibrateLow();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Primary contact changed successfully. ${contact.name} is now the primary contact.',
          ),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            emergencyContactErrorMessage(error, operation: 'set primary'),
          ),
        ),
      );
    }
  }

  Future<void> _delete(
    EmergencyContact contact, {
    required bool isPrimary,
    required EmergencyContact? replacement,
  }) async {
    final explanation = isPrimary
        ? replacement == null
              ? '${contact.name} will be removed. No emergency contacts will remain.'
              : '${contact.name} will be removed. ${replacement.name} will automatically become the primary contact.'
        : '${contact.name} will be removed from your emergency contacts.';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('Delete emergency contact?'),
        content: Semantics(
          label: 'Delete ${contact.name}. $explanation',
          child: ExcludeSemantics(child: Text(explanation)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep contact'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            child: const Text('Delete contact'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.deleteEmergencyContact(contact.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${contact.name} was deleted.')));
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            emergencyContactErrorMessage(error, operation: 'delete'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage emergency contacts')),
      body: StreamBuilder<List<EmergencyContact>>(
        stream: _contacts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ManagementError(
              message: emergencyContactErrorMessage(
                snapshot.error!,
                operation: 'load',
              ),
              onRetry: _retry,
            );
          }
          final contacts = snapshot.data ?? const <EmergencyContact>[];
          if (contacts.isEmpty) {
            return _EmptyContacts(
              onAdd: () => context.push(SafetyRoutes.addEmergencyContact),
            );
          }
          final explicitPrimary = contacts.where(
            (contact) => contact.isPrimary,
          );
          final primaryId = explicitPrimary.isNotEmpty
              ? explicitPrimary.first.id
              : contacts.first.id;
          final orderedContacts = [
            ...contacts.where((contact) => contact.id == primaryId),
            ...contacts.where((contact) => contact.id != primaryId),
          ];
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: orderedContacts.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Your primary contact is shown during SOS activation.',
                  ),
                );
              }
              final contact = orderedContacts[index - 1];
              final isPrimary = contact.id == primaryId;
              final replacement = orderedContacts
                  .where((candidate) => candidate.id != contact.id)
                  .firstOrNull;
              return _ContactManagementCard(
                contact: contact,
                isPrimary: isPrimary,
                onSetPrimary: () => _setPrimary(contact),
                onEdit: () => context.push(
                  SafetyRoutes.editEmergencyContactPath(contact.id),
                  extra: contact,
                ),
                onDelete: () => _delete(
                  contact,
                  isPrimary: isPrimary,
                  replacement: replacement,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(SafetyRoutes.addEmergencyContact),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add contact'),
      ),
    );
  }
}

class _ContactManagementCard extends StatelessWidget {
  const _ContactManagementCard({
    required this.contact,
    required this.isPrimary,
    required this.onSetPrimary,
    required this.onEdit,
    required this.onDelete,
  });

  final EmergencyContact contact;
  final bool isPrimary;
  final VoidCallback onSetPrimary;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.person_outline, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(contact.relationship),
                      Text(contact.phone),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isPrimary)
              Semantics(
                label: '${contact.name} is the primary emergency contact',
                child: Chip(
                  avatar: const Icon(Icons.star, size: 18),
                  label: const Text('Primary contact'),
                  backgroundColor: colors.primaryContainer,
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: onSetPrimary,
                icon: const Icon(Icons.star_outline),
                label: Text('Make ${contact.name} primary'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            const Divider(height: 28),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text('Edit ${contact.name}'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: Text('Delete ${contact.name}'),
                  style: TextButton.styleFrom(foregroundColor: colors.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyContacts extends StatelessWidget {
  const _EmptyContacts({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_add_alt_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              'No emergency contacts saved',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Add emergency contact'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementError extends StatelessWidget {
  const _ManagementError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
