import 'package:flutter/material.dart';
import '../models/translation_item.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';
// import 'package:http_parser/http_parser.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<TranslationItem> _favorites = [];
  List<TranslationItem> _filteredItems = [];
  bool _isSearching = false;
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String? _userName;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      _userName = prefs.getString('user_name');
      _userEmail = prefs.getString('user_email');
    });

    if (_isLoggedIn) {
      _fetchFavorites();
    }
  }

  // Migrate existing favorites to have proper timestamps
  Future<void> _migrateExistingFavorites(List<TranslationItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    for (final item in items) {
      final favoritedKey = 'favorited_${item.id}';
      final existingTime = prefs.getString(favoritedKey);

      // If no favorite timestamp exists, set it to now (for existing favorites)
      if (existingTime == null) {
        await prefs.setString(favoritedKey, now.toIso8601String());
      }
    }
  }

  Future<List<TranslationItem>> fetchFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url = Uri.parse('http://127.0.0.1:5000/favorites');
    final Map<String, String> headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      headers['x-access-token'] = token;
    }
    final response = await http.get(url, headers: headers);

    print('Favorites response: \n${response.body}'); // Debug print

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('Favorites data length: ${data.length}'); // Debug
      List<TranslationItem> items = [];
      for (var item in data) {
        try {
          final fav = TranslationItem.fromJson(item);

          // Get the actual favorited time from local storage
          final prefs = await SharedPreferences.getInstance();
          final favoritedKey = 'favorited_${fav.id}';
          final favoritedString = prefs.getString(favoritedKey);
          DateTime? favoritedTime;

          if (favoritedString != null) {
            favoritedTime = DateTime.tryParse(favoritedString);
          }

          // If no favorited time found, this means the item was favorited before we implemented timestamp tracking
          // In this case, we'll use the translation time as a reasonable approximation
          if (favoritedTime == null) {
            favoritedTime = fav.timestamp;
          }

          // Update the existing item with favorited time
          final favoriteWithTime = TranslationItem(
            id: fav.id,
            sourceText: fav.sourceText,
            translatedText: fav.translatedText,
            timestamp: fav.timestamp,
            isFavorite: fav.isFavorite,
            favoritedAt: favoritedTime,
          );
          items.add(favoriteWithTime);
        } catch (e) {
          print('Error parsing favorite: $e, item: $item');
        }
      }
      print('Parsed favorites: ${items.length}');

      // Migrate existing favorites to have timestamps
      await _migrateExistingFavorites(items);

      items.sort((a, b) => b.displayTimestamp.compareTo(a.displayTimestamp));
      return items;
    } else {
      throw Exception('Failed to load favorites');
    }
  }

  Future<void> _fetchFavorites() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final items = await fetchFavorites();
      if (mounted) {
        setState(() {
          _favorites = items;
          _filteredItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _favorites.where((item) {
        return item.sourceText.toLowerCase().contains(query) ||
            item.translatedText.toLowerCase().contains(query);
      }).toList();
      _filteredItems
          .sort((a, b) => b.displayTimestamp.compareTo(a.displayTimestamp));
    });
  }

  Future<void> deleteFavoriteById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url = Uri.parse('http://127.0.0.1:5000/favorites/$id');
    final Map<String, String> headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      headers['x-access-token'] = token;
    }
    final response = await http.delete(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete favorite');
    }

    // Remove the favorite timestamp from local storage
    final favoritedKey = 'favorited_$id';
    await prefs.remove(favoritedKey);

    _fetchFavorites();
  }

  Future<void> deleteAllFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url = Uri.parse('http://127.0.0.1:5000/favorites');
    final Map<String, String> headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      headers['x-access-token'] = token;
    }
    final response = await http.delete(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete all favorites');
    }

    // Remove all favorite timestamps from local storage
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('favorited_')) {
        await prefs.remove(key);
      }
    }

    _fetchFavorites();
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
                  hintText: 'Search favorites...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : Row(
                children: [
                  const Icon(
                    Icons.favorite,
                    size: 35,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Favorites',
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
                  _filteredItems = _favorites;
                }
              });
            },
          ),
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.delete, size: 30, color: Colors.white),
              onPressed: deleteAllFavorites,
            ),
        ],
      ),
      body: _isLoggedIn
          ? RefreshIndicator(
              onRefresh: _fetchFavorites,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredItems.isEmpty
                      ? Center(
                          child: Text(_favorites.isEmpty
                              ? 'No favorites yet'
                              : 'No results found'),
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
                                    Text(
                                      timeago.format(item.displayTimestamp),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await deleteFavoriteById(item.id);
                                  },
                                ),
                                onTap: () {
                                  print(
                                      'Tapped favorite: \n	xog: \n${item.sourceText} | ${item.translatedText}');
                                  Navigator.pop(context, item);
                                },
                              ),
                            );
                          },
                        ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Login Required',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please login to view your favorites',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AuthScreen(),
                        ),
                      );
                      if (!mounted) return;
                      final prefs = await SharedPreferences.getInstance();
                      final ok = (result == true) ||
                          (prefs.getBool('is_logged_in') ?? false);
                      if (ok) {
                        setState(() => _isLoggedIn = true);
                        _fetchFavorites();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Login / Register'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
    );
  }
}
