import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/firebase_service.dart';

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic>? extra;
  const ResultsScreen({super.key, this.extra});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  static const Color primaryBlue = Color(0xFF1B4FD8);

  late String searchTerm;
  late List<Map<String, dynamic>> results;
  int selectedIndex = 0;

  // NEW — tracks which place names are already saved as favorites
  Set<String> favoritedNames = {};

  @override
  void initState() {
    super.initState();
    searchTerm = widget.extra?['name'] ?? 'Destination';
    results = _generateMockResults(searchTerm);
    _loadFavorites(); // NEW — load existing favorites when screen opens
  }

  // Generates realistic nearby result variations from the search term.
  // NOTE: No live places/maps API is integrated in this timeframe (see docs/DEVIATIONS.md).
  List<Map<String, dynamic>> _generateMockResults(String term) {
    return [
      {'name': term, 'distance': '250 m'},
      {'name': '$term Station', 'distance': '600 m'},
      {'name': '$term Junction', 'distance': '1.2 km'},
      {'name': '$term Town', 'distance': '1.5 km'},
    ];
  }

  // NEW — READ: load all saved favorite names from Firestore
  Future<void> _loadFavorites() async {
    final data = await FirebaseService.getDocuments('saved_places');
    setState(() {
      favoritedNames = data.map((d) => d['name'] as String).toSet();
    });
  }

  // NEW — CREATE: save a place as a favorite
  Future<void> _toggleFavorite(String name) async {
    if (favoritedNames.contains(name)) return; // already saved, do nothing
    await FirebaseService.addDocument('saved_places', {'name': name});
    setState(() => favoritedNames.add(name));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name saved to favorites')),
      );
    }
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
                  Expanded(
                    child: Text(
                      searchTerm,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Search Results', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),

              // Results list
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final item = results[index];
                    final isSelected = index == selectedIndex;
                    final isFavorited = favoritedNames.contains(item['name']); // NEW

                    return GestureDetector(
                      onTap: () => setState(() => selectedIndex = index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
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
                            Icon(Icons.location_on,
                                color: isSelected ? primaryBlue : Colors.grey, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'],
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text('${item['distance']} away',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            // NEW — favorite heart button
                            IconButton(
                              icon: Icon(
                                isFavorited ? Icons.favorite : Icons.favorite_border,
                                color: isFavorited ? Colors.red : Colors.grey,
                                size: 20,
                              ),
                              onPressed: () => _toggleFavorite(item['name']),
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

              // Select Location button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final selected = results[selectedIndex];
                    context.push('/routes', extra: {
                      'destinationName': selected['name'],
                      'distance': selected['distance'],
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: const Text('Select Location'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}