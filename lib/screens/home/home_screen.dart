import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryBlue = Color(0xFF1B4FD8);

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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.explore, color: primaryBlue),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'NavAssist',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Current location card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.06),
                  border: Border.all(color: primaryBlue.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 20, color: primaryBlue),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Current Location', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text('Kandy City Centre', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Search field
              GestureDetector(
                onTap: () => context.push('/search'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.search, size: 18, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Where do you want to go?', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Voice search button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/search'),
                  icon: const Icon(Icons.mic),
                  label: const Text('Voice Search'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Recent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),

              // Recent searches — live Firestore stream
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirebaseService.streamRecentSearches(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: primaryBlue));
                    }
                    final recentSearches = snapshot.data ?? [];
                    if (recentSearches.isEmpty) {
                      return const Text('No recent searches yet', style: TextStyle(color: Colors.grey));
                    }
                    return ListView.builder(
                      itemCount: recentSearches.length,
                      itemBuilder: (context, index) {
                        final item = recentSearches[index];
                        return Dismissible(
                              key: Key(item['id']),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              onDismissed: (direction) {
                                FirebaseService.deleteDocument('recent_searches', item['id']);
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 6),
                                elevation: 0,
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.location_on_outlined, color: primaryBlue),
                                  title: Text(item['name'] ?? ''),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    context.push('/results', extra: {'name': item['name']});
                                  },
                                ),
                              ),
                            );
                          },
                       );
                    },
                  ),
                ),

              // SOS button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SOS pressed (placeholder)')),
                    );
                  },
                  icon: const Icon(Icons.warning_amber, color: Colors.red),
                  label: const Text('SOS', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.place), label: 'Places'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}