import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/firebase_service.dart';

class RouteDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? extra;
  const RouteDetailsScreen({super.key, this.extra});

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  static const Color primaryBlue = Color(0xFF1B4FD8);

  String? _historyDocId;

  @override
  void initState() {
    super.initState();
    _logRouteView();
  }

  // NEW — CREATE: logs that this route was viewed, as soon as the screen opens
  Future<void> _logRouteView() async {
    try {
      final id = await FirebaseService.addDocument('route_history', {
        'destinationName': widget.extra?['destinationName'] ?? 'Destination',
        'reviewed': false,
      });
      setState(() => _historyDocId = id);
    } catch (e) {
      debugPrint('Error logging route view: $e');
    }
  }

  // NEW — UPDATE: marks that record as reviewed once the user taps Start Navigation
  Future<void> _markReviewed() async {
    if (_historyDocId == null) return;
    try {
      await FirebaseService.updateDocument('route_history', _historyDocId!, {
        'reviewed': true,
      });
    } catch (e) {
      debugPrint('Error marking route reviewed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinationName = widget.extra?['destinationName'] ?? 'Destination';
    final time = widget.extra?['time'] ?? '15 min';
    final distance = widget.extra?['distance'] ?? '1.2 km';

    // Representative turn-by-turn steps.
    // NOTE: No live routing/directions API integrated in this timeframe (see docs/DEVIATIONS.md).
    final steps = [
      'Walk straight for 150 m',
      'Turn left at the junction',
      'Cross one road',
      'Continue for 400 m',
      'Destination on your right',
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  const Text(
                    'Route Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Destination summary card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.06),
                  border: Border.all(color: primaryBlue.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: primaryBlue, size: 22),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(destinationName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('$distance · $time',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text('Turn-by-turn Directions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),

              // Scrollable step list + warning
              Expanded(
                child: ListView(
                  children: [
                    ...List.generate(steps.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: primaryBlue,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(steps[index], style: const TextStyle(fontSize: 13.5)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),

                    // Safety warning block
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.08),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Road crossing ahead · Construction area',
                              style: TextStyle(fontSize: 12.5, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Start Navigation button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _markReviewed(); // NEW — Update call before navigating
                    if (context.mounted) {
                      context.push('/navigate-start', extra: {
                        'destinationName': destinationName,
                        'distance': distance,
                        'time': time,
                      });
                    }
                  },
                  icon: const Icon(Icons.navigation),
                  label: const Text('Start Navigation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}