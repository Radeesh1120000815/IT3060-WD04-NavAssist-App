import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RouteOptionsScreen extends StatefulWidget {
  final Map<String, dynamic>? extra;
  const RouteOptionsScreen({super.key, this.extra});

  @override
  State<RouteOptionsScreen> createState() => _RouteOptionsScreenState();
}

class _RouteOptionsScreenState extends State<RouteOptionsScreen> {
  static const Color primaryBlue = Color(0xFF1B4FD8);

  late String destinationName;
  late List<Map<String, dynamic>> routes;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    destinationName = widget.extra?['destinationName'] ?? 'Destination';
    routes = _generateRoutes();
  }

  // Generates representative route options with safety-first ordering.
  // NOTE: No live routing/maps API integrated in this timeframe (see docs/DEVIATIONS.md).
  List<Map<String, dynamic>> _generateRoutes() {
    return [
      {
        'name': 'Route 1',
        'icon': Icons.verified,
        'time': '15 min',
        'distance': '1.2 km',
        'note': 'Safest route',
        'recommended': true,
      },
      {
        'name': 'Route 2',
        'icon': Icons.bolt,
        'time': '12 min',
        'distance': '1.0 km',
        'note': '2 road crossings',
        'recommended': false,
      },
      {
        'name': 'Route 3',
        'icon': Icons.watch_later_outlined,
        'time': '18 min',
        'distance': '1.4 km',
        'note': 'Less crowded',
        'recommended': false,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
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
                    'Route Options',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Text(
                  'To $destinationName',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 14),

              // Route cards
              Expanded(
                child: ListView.builder(
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    final route = routes[index];
                    final isSelected = index == selectedIndex;
                    final isRecommended = route['recommended'] == true;

                    return GestureDetector(
                      onTap: () => setState(() => selectedIndex = index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryBlue.withValues(alpha: 0.06) : Colors.white,
                          border: Border.all(
                            color: isSelected ? primaryBlue : Colors.grey.shade200,
                            width: isSelected ? 1.6 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isRecommended
                                    ? primaryBlue.withValues(alpha: 0.12)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                route['icon'],
                                color: isRecommended ? primaryBlue : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(route['name'],
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      if (isRecommended) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: primaryBlue,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text('Recommended',
                                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text('${route['time']} · ${route['distance']}',
                                      style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                  Text(route['note'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isRecommended ? primaryBlue : Colors.grey.shade600,
                                        fontWeight: isRecommended ? FontWeight.w600 : FontWeight.normal,
                                      )),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: primaryBlue, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Select Route button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final selected = routes[selectedIndex];
                    context.push('/details', extra: {
                      'destinationName': destinationName,
                      'time': selected['time'],
                      'distance': selected['distance'],
                      'routeName': selected['name'],
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: const Text('Select Route'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}