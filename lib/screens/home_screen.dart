import 'package:flutter/material.dart';
import 'translation_screen.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'setting_screen.dart';
import 'auth_screen.dart';
import 'recordings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkMode;
  final double textSize;
  final Function(double) onTextSizeChanged;

  const HomeScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
    required this.textSize,
    required this.onTextSizeChanged,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoggedIn = false;
  String _userName = '';
  String _userPhone = '';

  @override
  void initState() {
    super.initState();
    _clearInvalidLoginState();
    _checkLoginStatus();
  }

  Future<void> _clearInvalidLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final authToken = prefs.getString('auth_token');

    // If login flag is true but no token, clear the login state
    if (isLoggedIn && (authToken == null || authToken.isEmpty)) {
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('user_name');
      await prefs.remove('user_phone');
      await prefs.remove('user_role');
      print('Cleared invalid login state');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh login status when dependencies change
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final authToken = prefs.getString('auth_token');

    // Check if user is actually logged in (has token and login flag)
    final actuallyLoggedIn =
        isLoggedIn && authToken != null && authToken.isNotEmpty;

    setState(() {
      _isLoggedIn = actuallyLoggedIn;
      _userName = prefs.getString('user_name') ?? '';
      _userPhone = prefs.getString('user_phone') ?? '';
    });

    // If login flag is true but no token, clear the login state
    if (isLoggedIn && (authToken == null || authToken.isEmpty)) {
      await prefs.setBool('is_logged_in', false);
      setState(() {
        _isLoggedIn = false;
        _userName = '';
        _userPhone = '';
      });
    }

    // Debug print
    print(
        'Login status check: isLoggedIn=$isLoggedIn, authToken=${authToken?.isNotEmpty}, _isLoggedIn=$_isLoggedIn');
  }

  Future<void> _onDrawerSelect(int index) async {
    Navigator.pop(context); // Close the drawer
    if (index == 0) {
      // Already on TranslationScreen, do nothing
      return;
    } else if (index == 1) {
      if (!_isLoggedIn) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
        if (result == true) {
          await _checkLoginStatus();
        }
        return;
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FavoritesScreen()),
      );
    } else if (index == 2) {
      // History - requires login
      if (!_isLoggedIn) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
        if (result == true) {
          await _checkLoginStatus();
        }
        return;
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HistoryScreen()),
      );
    } else if (index == 4) {
      // Voice recordings - requires login
      if (!_isLoggedIn) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
        if (result == true) {
          await _checkLoginStatus();
        }
        return;
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RecordingsScreen()),
      );
    } else if (index == 5) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SettingScreen(
            settingsItems: const [],
            toggleTheme: widget.toggleTheme,
            isDarkMode: widget.isDarkMode,
            onTextSizeChanged: widget.onTextSizeChanged,
          ),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_phone');
    await prefs.remove('user_role');
    await prefs.setBool('is_logged_in', false);
    if (!mounted) return;
    setState(() {
      _isLoggedIn = false;
      _userName = '';
      _userPhone = '';
    });
    Navigator.pop(context); // close drawer
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.translate, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  const Text(
                    'Translation App',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isLoggedIn && _userName.isNotEmpty)
                    Text(
                      'Welcome, $_userName',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    )
                  else if (_isLoggedIn && _userPhone.isNotEmpty)
                    Text(
                      'Welcome, $_userPhone',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    )
                  else if (_isLoggedIn)
                    const Text(
                      'Welcome, User',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    )
                  else
                    const Text(
                      'Guest Mode',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.translate),
              title: const Text('Translation'),
              selected: true,
              onTap: () => _onDrawerSelect(0),
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favorites'),
              onTap: () => _onDrawerSelect(1),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History'),
              onTap: () => _onDrawerSelect(2),
            ),
            // Voice recordings - only for logged-in users
            if (_isLoggedIn)
              ListTile(
                leading: const Icon(Icons.mic),
                title: const Text('Voice Recordings'),
                onTap: () => _onDrawerSelect(4),
              ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () => _onDrawerSelect(5),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share App'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            // Only show logout if user is logged in
            if (_isLoggedIn)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: _logout,
              ),
          ],
        ),
      ),
      drawerEnableOpenDragGesture: false,
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          _checkLoginStatus();
        }
      },
      body: TranslationScreen(
        toggleTheme: widget.toggleTheme,
        isDarkMode: widget.isDarkMode,
        openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        textSize: widget.textSize,
      ),
    );
  }
}
