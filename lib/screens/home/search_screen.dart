import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../services/firebase_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const Color primaryBlue = Color(0xFF1B4FD8);

  final TextEditingController _controller = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();

  List<Map<String, dynamic>> recentSearches = [];
  bool isLoading = true;
  bool isListening = false;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final data = await FirebaseService.getDocuments('recent_searches');
    setState(() {
      recentSearches = data;
      isLoading = false;
    });
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => isListening = false);
        }
      },
      onError: (error) {
        setState(() => isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice error: ${error.errorMsg}')),
        );
      },
    );

    if (available) {
      setState(() => isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
          });
        },
      );
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available on this device')),
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => isListening = false);
  }

  Future<void> _submitSearch(String query) async {
  debugPrint('=== _submitSearch called with: "$query" ===');
  if (query.trim().isEmpty) {
    debugPrint('=== Empty query, returning early ===');
    return;
  }

  try {
    await FirebaseService.addOrUpdateRecentSearch(query);
    debugPrint('=== Firestore save SUCCEEDED ===');
  } catch (e, stack) {
    debugPrint('=== Firestore save FAILED: $e ===');
    debugPrint('=== Stack: $stack ===');
  }

  if (!mounted) {
    debugPrint('=== Widget not mounted, aborting navigation ===');
    return;
  }

  debugPrint('=== About to navigate to /results ===');
  context.push('/results', extra: {'name': query.trim()});
  debugPrint('=== Navigation call completed ===');
}
  @override
  void dispose() {
    _controller.dispose();
    _speech.stop();
    super.dispose();
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
                    'Search Destination',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Text search field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Enter destination...',
                    prefixIcon: Icon(Icons.search, size: 20),
                    border: InputBorder.none,
                  ),
                  onSubmitted: _submitSearch,
                ),
              ),
              const SizedBox(height: 10),

              // Voice search button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isListening ? _stopListening : _startListening,
                  icon: Icon(isListening ? Icons.mic : Icons.mic_none),
                  label: Text(isListening ? 'Listening... Tap to stop' : 'Speak Destination'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isListening ? Colors.red : primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                ),
              ),

              // When voice input finishes, offer a quick "search this" button
              if (!isListening && _controller.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _submitSearch(_controller.text),
                      child: Text('Search "${_controller.text}"'),
                    ),
                  ),
                ),

              const SizedBox(height: 16),
              const Text('Recent Searches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),

              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                    : recentSearches.isEmpty
                        ? const Text('No recent searches yet', style: TextStyle(color: Colors.grey))
                        : ListView.builder(
                            itemCount: recentSearches.length,
                            itemBuilder: (context, index) {
                              final item = recentSearches[index];
                              return Card(
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
                                  onTap: () => _submitSearch(item['name'] ?? ''),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}