import 'package:flutter/material.dart';
import '../models/translation_item.dart';
import 'dart:convert'; // Added for json
import 'package:http/http.dart' as http; // Added for http requests
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<TranslationItem> _allItems = [];
  List<TranslationItem> _filteredItems = [];
  bool _isSearching = false;
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    setState(() {
      _isLoggedIn = isLoggedIn;
    });

    if (isLoggedIn) {
      _fetchHistory();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _allItems.where((item) {
        return item.sourceText.toLowerCase().contains(query) ||
            item.translatedText.toLowerCase().contains(query);
      }).toList();
      // Sort filtered items as well
      _filteredItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  void _clearHistory() async {
    if (!_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to clear history')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear History'),
          content: const Text('Are you sure you want to clear all history?'),
          actions: [
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () => Navigator.pop(context, false),
            ),
            TextButton(
              child: const Text('CLEAR', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      try {
        await deleteAllHistory();
        _fetchHistory(); // Dib u soo celi history-ga cusub
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing history: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search history...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : const Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 35,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'History',
                    style: TextStyle(fontSize: 27, color: Colors.white),
                  ),
                ],
              ),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              size: 30,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredItems = _allItems;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 30, color: Colors.white),
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchHistory,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : !_isLoggedIn
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.login, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Login required to view history',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            // Navigate to auth screen
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const AuthScreen()),
                            );
                            if (result == true) {
                              _checkLoginStatus();
                            }
                          },
                          child: const Text('Login'),
                        ),
                      ],
                    ),
                  )
                : _filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.history,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              _allItems.isEmpty
                                  ? 'No history yet'
                                  : 'No results found',
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(item.sourceText),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.translatedText),
                                  const SizedBox(height: 4),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatTimestamp(item.timestamp),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      if (!_isLoggedIn) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Please login to delete items')),
                                        );
                                        return;
                                      }
                                      try {
                                        await deleteHistoryItem(item.id);
                                        _fetchHistory(); // dib u load garee
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Error deleting item: $e')),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                print(
                                    'Tapped history: \n	xog: \n${item.sourceText} | ${item.translatedText}');
                                Navigator.pop(context, item);
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<List<TranslationItem>> fetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url = Uri.parse('http://127.0.0.1:5000/history');

    final Map<String, String> headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      headers['x-access-token'] = token;
    }

    final response = await http.get(url, headers: headers);
    print('History response: \n${response.body}'); // Debug print

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> data = responseData['translations'] ?? [];
      List<TranslationItem> items =
          data.map((item) => TranslationItem.fromJson(item)).toList();
      // Sort: latest first
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return items;
    } else {
      throw Exception('Failed to load history');
    }
  }

  Future<void> deleteAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url = Uri.parse('http://127.0.0.1:5000/history');

    final Map<String, String> headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      headers['x-access-token'] = token;
    }

    final response = await http.delete(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete all history');
    }
  }

  Future<void> deleteHistoryItem(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url = Uri.parse('http://127.0.0.1:5000/history/$id');

    final Map<String, String> headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      headers['x-access-token'] = token;
    }

    final response = await http.delete(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete history item');
    }
  }

  Future<void> _fetchHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final items = await fetchHistory();
      if (mounted) {
        setState(() {
          _allItems = items;
          _filteredItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e')),
        );
      }
    }
  }
}
