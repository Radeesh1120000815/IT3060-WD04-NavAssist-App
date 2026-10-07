import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/hazard.dart';
import 'data/hazard_repository.dart';
import 'widgets/safety_widgets.dart';

enum HazardCategory { blockedPath, pothole, construction, other }

extension HazardCategoryDetails on HazardCategory {
  String get label => switch (this) {
    HazardCategory.blockedPath => 'Blocked path',
    HazardCategory.pothole => 'Pothole',
    HazardCategory.construction => 'Construction',
    HazardCategory.other => 'Other',
  };

  IconData get icon => switch (this) {
    HazardCategory.blockedPath => Icons.block_outlined,
    HazardCategory.pothole => Icons.warning_amber_rounded,
    HazardCategory.construction => Icons.construction_outlined,
    HazardCategory.other => Icons.more_horiz,
  };

  HazardSeverity get automaticSeverity => switch (this) {
    HazardCategory.blockedPath => HazardSeverity.high,
    HazardCategory.pothole => HazardSeverity.medium,
    HazardCategory.construction => HazardSeverity.high,
    HazardCategory.other => HazardSeverity.low,
  };
}

class ReportHazardScreen extends StatefulWidget {
  const ReportHazardScreen({
    super.key,
    this.hazardId,
    this.initialHazard,
    this.repository,
  });

  final String? hazardId;
  final Hazard? initialHazard;
  final HazardDataSource? repository;

  bool get isEditing => hazardId != null;

  @override
  State<ReportHazardScreen> createState() => _ReportHazardScreenState();
}

class _ReportHazardScreenState extends State<ReportHazardScreen> {
  static const _demoLocation = 'Main Street, near the bus stop';

  final _noteController = TextEditingController();
  final _firstCategoryFocus = FocusNode();
  late final HazardDataSource _repository;
  HazardCategory? _selectedCategory;
  Hazard? _editingHazard;
  String? _categoryError;
  String? _loadError;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? HazardRepository();
    if (widget.isEditing) {
      final initial = widget.initialHazard;
      if (initial != null) {
        _applyHazard(initial);
      } else {
        _loadHazard();
      }
    }
  }

  void _applyHazard(Hazard hazard) {
    if (hazard.reporterId != _repository.currentUserId) {
      _loadError = 'You can only edit hazards that you reported.';
      return;
    }
    _editingHazard = hazard;
    _selectedCategory = HazardCategory.values.firstWhere(
      (category) => category.label.toLowerCase() == hazard.type.toLowerCase(),
      orElse: () => HazardCategory.other,
    );
    _noteController.text = hazard.description;
  }

  Future<void> _loadHazard() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final hazard = await _repository.getHazard(widget.hazardId!);
      if (!mounted) return;
      if (hazard == null) {
        setState(() => _loadError = 'This hazard report no longer exists.');
      } else {
        setState(() => _applyHazard(hazard));
      }
    } on Object {
      if (!mounted) return;
      setState(
        () => _loadError = 'Could not load this report. Check your connection and permissions.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _firstCategoryFocus.dispose();
    super.dispose();
  }

  void _selectCategory(HazardCategory category) {
    setState(() {
      _selectedCategory = category;
      _categoryError = null;
    });
  }

  Future<void> _submit() async {
    final category = _selectedCategory;
    if (category == null) {
      setState(() {
        _categoryError = 'Select one hazard category before submitting.';
      });
      _firstCategoryFocus.requestFocus();
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (widget.isEditing) {
        final existing = _editingHazard;
        if (existing == null) {
          throw const HazardRepositoryException(
            'This hazard report could not be edited.',
          );
        }
        await _repository.updateHazard(
          hazardId: existing.id,
          type: category.label,
          description: _noteController.text.trim(),
          locationName: existing.locationName,
          latitude: existing.latitude,
          longitude: existing.longitude,
          severity: category.automaticSeverity,
        );
      } else {
        await _repository.createHazard(
          type: category.label,
          description: _noteController.text.trim(),
          locationName: _demoLocation,
          latitude: null,
          longitude: null,
          severity: category.automaticSeverity,
        );
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline, size: 40),
          title: Text(widget.isEditing ? 'Report updated' : 'Report submitted'),
          content: Text(
            widget.isEditing
                ? '${category.label} was updated successfully.'
                : '${category.label} was saved to community hazards.',
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_friendlySaveError(error))));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit hazard report' : 'Report a hazard',
        ),
      ),
      body: _isLoading
          ? Center(
              child: Semantics(
                liveRegion: true,
                label: 'Loading hazard report',
                child: const CircularProgressIndicator(),
              ),
            )
          : _loadError != null
          ? _EditLoadError(message: _loadError!, onRetry: _loadHazard)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const DemoDataBanner(
                  message: 'Reports are saved to the community. The displayed location is still a demo value.',
                ),
                const SizedBox(height: 20),
                const SafetySectionTitle('What did you find?'),
                const SizedBox(height: 4),
                Text(
                  'Select one hazard category.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                for (final (index, category) in HazardCategory.values.indexed)
                  _CategoryCard(
                    category: category,
                    selected: _selectedCategory == category,
                    focusNode: index == 0 ? _firstCategoryFocus : null,
                    onTap: () => _selectCategory(category),
                  ),
                if (_categoryError != null) ...[
                  const SizedBox(height: 6),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _categoryError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const SafetySectionTitle('Optional note'),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Add a short note (optional)',
                    hintText: 'For example, the right side is still passable',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const SafetySectionTitle('Location'),
                const SizedBox(height: 8),
                _DemoLocationCard(
                  locationName: _editingHazard?.locationName ?? _demoLocation,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          widget.isEditing
                              ? Icons.save_outlined
                              : Icons.send_outlined,
                        ),
                  label: Text(
                    _isSaving
                        ? 'Saving report...'
                        : widget.isEditing
                        ? 'Save changes'
                        : 'Submit report',
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

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.onTap,
    this.focusNode,
  });

  final HazardCategory category;
  final bool selected;
  final VoidCallback onTap;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '${category.label}, hazard category',
      hint: selected ? 'Selected' : 'Double tap to select',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: selected ? 1 : 0,
          color: selected ? colors.primaryContainer : colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 2.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            focusNode: focusNode,
            excludeFromSemantics: true,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      category.icon,
                      size: 30,
                      color: selected
                          ? colors.onPrimaryContainer
                          : colors.onSurface,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.label,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(selected ? 'Selected' : 'Tap to select'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: selected
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoLocationCard extends StatelessWidget {
  const _DemoLocationCard({required this.locationName});

  final String locationName;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Demo location. $locationName.',
      child: ExcludeSemantics(
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.my_location_outlined, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locationName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Demo location - not detected from this device',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditLoadError extends StatelessWidget {
  const _EditLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
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
      ),
    );
  }
}

String _friendlySaveError(Object error) {
  if (error is HazardRepositoryException) return error.message;
  return 'The report could not be saved. Check your connection and Firestore permissions.';
}
