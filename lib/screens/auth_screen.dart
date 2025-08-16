import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Login controllers
  final TextEditingController _loginPhoneController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();

  // Register controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSubmitting = false;
  String? _loginErrorText;
  String? _registerErrorText;
  bool _obscurePassword = true;

  // Real-time validation states
  bool _isNameValid = true;
  bool _isPhoneValid = true;
  bool _isLoginPhoneValid = true;
  bool _isLoginPasswordValid = true;

  // Track which form is currently active
  bool _isOnLoginForm = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });

    // Add listeners for real-time validation
    _nameController.addListener(_validateName);
    _phoneController.addListener(_validatePhone);
    _loginPhoneController.addListener(_validateLoginPhone);
    _loginPasswordController.addListener(_validateLoginPassword);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginPhoneController.dispose();
    _loginPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _persistSession({
    required String phone,
    required String token,
    String? name,
    String? role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_phone', phone);
    await prefs.setString('auth_token', token);
    if (name != null && name.isNotEmpty) {
      await prefs.setString('user_name', name);
    }
    if (role != null && role.isNotEmpty) {
      await prefs.setString('user_role', role);
    }
  }

  Uri _api(String path) => Uri.parse('http://127.0.0.1:5000$path');

  // Real-time validation functions
  void _validateName() {
    final name = _nameController.text.trim();
    print('Validating name: "$name"'); // Debug print

    if (name.isEmpty) {
      setState(() {
        _isNameValid = true; // Don't show error for empty field initially
      });
      print('Name is empty, setting valid to true');
      return;
    }

    // Check if name contains only letters and spaces (no numbers allowed)
    final isValid = RegExp(r'^[a-zA-Z\s]+$').hasMatch(name) && name.length >= 2;
    print('Name validation result: $isValid'); // Debug print
    setState(() {
      _isNameValid = isValid;
    });
  }

  void _validatePhone() {
    final phone = _phoneController.text.trim();
    print('Validating phone: "$phone"'); // Debug print

    if (phone.isEmpty) {
      setState(() {
        _isPhoneValid = true; // Don't show error for empty field initially
      });
      print('Phone is empty, setting valid to true');
      return;
    }

    // Remove spaces and special characters for validation
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    bool isValid = false;

    // Check if it starts with 252 (country code)
    if (cleanPhone.startsWith('252')) {
      // Should be 12 digits total (252 + 9 digits)
      isValid =
          cleanPhone.length == 12 && RegExp(r'^[0-9]+$').hasMatch(cleanPhone);
    }
    // Check if it starts with +252
    else if (cleanPhone.startsWith('+252')) {
      // Should be 13 digits total (+252 + 9 digits)
      isValid =
          cleanPhone.length == 13 && RegExp(r'^\+[0-9]+$').hasMatch(cleanPhone);
    }
    // Check if it's just 9 digits (local format)
    else if (cleanPhone.length == 9 &&
        RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
      isValid = true;
    }

    print('Phone validation result: $isValid'); // Debug print
    setState(() {
      _isPhoneValid = isValid;
    });
  }

  void _validateLoginPhone() {
    final phone = _loginPhoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _isLoginPhoneValid = true; // Don't show error for empty field initially
      });
      return;
    }

    // Remove spaces and special characters for validation
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    bool isValid = false;

    // Check if it starts with 252 (country code)
    if (cleanPhone.startsWith('252')) {
      // Should be 12 digits total (252 + 9 digits)
      isValid =
          cleanPhone.length == 12 && RegExp(r'^[0-9]+$').hasMatch(cleanPhone);
    }
    // Check if it starts with +252
    else if (cleanPhone.startsWith('+252')) {
      // Should be 13 digits total (+252 + 9 digits)
      isValid =
          cleanPhone.length == 13 && RegExp(r'^\+[0-9]+$').hasMatch(cleanPhone);
    }
    // Check if it's just 9 digits (local format)
    else if (cleanPhone.length == 9 &&
        RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
      isValid = true;
    }

    setState(() {
      _isLoginPhoneValid = isValid;
    });
  }

  void _validateLoginPassword() {
    final password = _loginPasswordController.text.trim();
    if (password.isEmpty) {
      setState(() {
        _isLoginPasswordValid =
            true; // Don't show error for empty field initially
      });
      return;
    }

    // Check if password has at least 6 characters
    final isValid = password.length >= 6;
    setState(() {
      _isLoginPasswordValid = isValid;
    });
  }

  Future<void> _onLogin() async {
    if (_isSubmitting) return;

    // Validate phone number (Somali format)
    final phone = _loginPhoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _loginErrorText = 'Phone number is required';
        _isSubmitting = false;
      });
      return;
    }

    // Remove spaces and special characters for validation
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    bool isValid = false;

    // Check if it starts with 252 (country code)
    if (cleanPhone.startsWith('252')) {
      // Should be 12 digits total (252 + 9 digits)
      isValid =
          cleanPhone.length == 12 && RegExp(r'^[0-9]+$').hasMatch(cleanPhone);
    }
    // Check if it starts with +252
    else if (cleanPhone.startsWith('+252')) {
      // Should be 13 digits total (+252 + 9 digits)
      isValid =
          cleanPhone.length == 13 && RegExp(r'^\+[0-9]+$').hasMatch(cleanPhone);
    }
    // Check if it's just 9 digits (local format)
    else if (cleanPhone.length == 9 &&
        RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
      isValid = true;
    }

    if (!isValid) {
      setState(() {
        _loginErrorText =
            'Invalid phone number format. Use Somali format: 252XXXXXXXXX or +252XXXXXXXXX or XXXXXXXXX (9 digits)';
        _isSubmitting = false;
      });
      return;
    }

    // Validate password
    final password = _loginPasswordController.text.trim();
    if (password.isEmpty) {
      setState(() {
        _loginErrorText = 'Password is required';
        _isSubmitting = false;
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _loginErrorText = 'Password must be at least 6 characters';
        _isSubmitting = false;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _loginErrorText = null;
    });
    try {
      final resp = await http.post(
        _api('/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone': _loginPhoneController.text.trim(),
          'password': _loginPasswordController.text.trim(),
        }),
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final token = (data['token'] ?? '').toString();
        final role = (data['role'] ?? '').toString();
        final fullName = (data['full_name'] ?? '').toString();
        if (token.isEmpty) {
          throw Exception('Empty token');
        }
        await _persistSession(
          phone: _loginPhoneController.text.trim(),
          token: token,
          name: fullName,
          role: role,
        );
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        final msg = _extractError(resp.body) ?? 'Login failed';
        _showSnack(context, msg);
        setState(() => _loginErrorText = msg);
      }
    } catch (e) {
      _showSnack(context, 'Network error');
      setState(() => _loginErrorText = 'Network error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _onRegister() async {
    if (_isSubmitting) return;

    // Validate full name (only letters and spaces, no numbers)
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _registerErrorText = 'Full name is required';
        _isSubmitting = false;
      });
      return;
    }

    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name) || name.length < 2) {
      setState(() {
        _registerErrorText =
            'Full name must contain only letters and spaces, and be at least 2 characters long';
        _isSubmitting = false;
      });
      return;
    }

    // Validate phone number (Somali format)
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _registerErrorText = 'Phone number is required';
        _isSubmitting = false;
      });
      return;
    }

    // Remove spaces and special characters for validation
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    bool isValid = false;

    // Check if it starts with 252 (country code)
    if (cleanPhone.startsWith('252')) {
      // Should be 12 digits total (252 + 9 digits)
      isValid =
          cleanPhone.length == 12 && RegExp(r'^[0-9]+$').hasMatch(cleanPhone);
    }
    // Check if it starts with +252
    else if (cleanPhone.startsWith('+252')) {
      // Should be 13 digits total (+252 + 9 digits)
      isValid =
          cleanPhone.length == 13 && RegExp(r'^\+[0-9]+$').hasMatch(cleanPhone);
    }
    // Check if it's just 9 digits (local format)
    else if (cleanPhone.length == 9 &&
        RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
      isValid = true;
    }

    if (!isValid) {
      setState(() {
        _registerErrorText =
            'Invalid phone number format. Use Somali format: 252XXXXXXXXX or +252XXXXXXXXX or XXXXXXXXX (9 digits)';
        _isSubmitting = false;
      });
      return;
    }

    // Validate password
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() {
        _registerErrorText = 'Password is required';
        _isSubmitting = false;
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _registerErrorText = 'Password must be at least 6 characters';
        _isSubmitting = false;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _registerErrorText = null;
    });
    try {
      final resp = await http.post(
        _api('/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'full_name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text.trim(),
          'role': 'user',
        }),
      );
      if (resp.statusCode == 201) {
        // Show success message and redirect to login page
        _showSnack(context, 'Account created successfully! Please login.');
        Navigator.pop(context); // Go back to login page
      } else {
        final msg = _extractError(resp.body) ?? 'Registration failed';
        _showSnack(context, msg);
        setState(() => _registerErrorText = msg);
      }
    } catch (e) {
      _showSnack(context, 'Network error');
      setState(() => _registerErrorText = 'Network error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _extractError(String body) {
    try {
      final obj = json.decode(body);
      if (obj is Map && obj['error'] != null) {
        return obj['error'].toString();
      }
    } catch (_) {}
    return null;
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: const Text('Account', style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [Colors.black, Colors.black87]
                : [const Color(0xFFE3F2FD), const Color(0xFFFFFFFF)],
          ),
        ),
        child: Column(
          children: [
            const _AuthHeader(isLogin: true),
            const SizedBox(height: 8),
            Expanded(
              child: _LoginForm(
                phoneController: _loginPhoneController,
                passwordController: _loginPasswordController,
                onSubmit: _onLogin,
                isSubmitting: _isSubmitting,
                errorText: _loginErrorText,
                isPhoneValid: _isLoginPhoneValid,
                isPasswordValid: _isLoginPasswordValid,
                isOnLoginForm: _isOnLoginForm,
                obscurePassword: _obscurePassword,
                onTogglePasswordVisibility: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onSwitchToRegister: () async {
                  setState(() {
                    _isOnLoginForm = false;
                  });
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Create account')),
                        body: _RegisterForm(
                          nameController: _nameController,
                          phoneController: _phoneController,
                          passwordController: _passwordController,
                          onSubmit: _onRegister,
                          isSubmitting: _isSubmitting,
                          errorText: _registerErrorText,
                          isNameValid: _isNameValid,
                          isPhoneValid: _isPhoneValid,
                          obscurePassword: _obscurePassword,
                          onTogglePasswordVisibility: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          onSwitchToLogin: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  );
                  setState(() {
                    _isOnLoginForm = true;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;
  final bool isSubmitting;
  final String? errorText;
  final bool isPhoneValid;
  final bool isPasswordValid;
  final bool isOnLoginForm;
  final VoidCallback onSwitchToRegister;
  final bool obscurePassword;
  final VoidCallback onTogglePasswordVisibility;

  const _LoginForm({
    required this.phoneController,
    required this.passwordController,
    required this.onSubmit,
    required this.isSubmitting,
    required this.errorText,
    required this.isPhoneValid,
    required this.isPasswordValid,
    required this.isOnLoginForm,
    required this.onSwitchToRegister,
    required this.obscurePassword,
    required this.onTogglePasswordVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            elevation: 8,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[900]
                : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  // Icon for login
                  Container(
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_open_rounded,
                      color: Colors.blue.shade700,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Welcome back',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text('Login to continue',
                      style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  if (errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(errorText!,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: const OutlineInputBorder(),
                      errorText: isOnLoginForm &&
                              !isPhoneValid &&
                              phoneController.text.isNotEmpty
                          ? 'Invalid phone format. Use: 252XXXXXXXXX, +252XXXXXXXXX, or XXXXXXXXX'
                          : null,
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      errorText: isOnLoginForm &&
                              !isPasswordValid &&
                              passwordController.text.isNotEmpty
                          ? 'Password must be at least 6 characters'
                          : null,
                      suffixIcon: IconButton(
                        icon: Icon(obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: onTogglePasswordVisibility,
                      ),
                    ),
                    obscureText: obscurePassword,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isSubmitting ? 'Please wait...' : 'Login'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: onSwitchToRegister,
                        child: const Text('Sign up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;
  final bool isSubmitting;
  final String? errorText;
  final bool isNameValid;
  final bool isPhoneValid;
  final VoidCallback onSwitchToLogin;
  final bool obscurePassword;
  final VoidCallback onTogglePasswordVisibility;

  const _RegisterForm({
    required this.nameController,
    required this.phoneController,
    required this.passwordController,
    required this.onSubmit,
    required this.isSubmitting,
    required this.errorText,
    required this.isNameValid,
    required this.isPhoneValid,
    required this.onSwitchToLogin,
    required this.obscurePassword,
    required this.onTogglePasswordVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            elevation: 8,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[900]
                : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  // Icon for signup
                  Container(
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Colors.blue.shade700,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Create account',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text('Sign up to get started',
                      style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  if (errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(errorText!,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: const OutlineInputBorder(),
                      errorText: !isNameValid && nameController.text.isNotEmpty
                          ? 'Full name must contain only letters and spaces, min 2 characters'
                          : null,
                    ),
                    onChanged: (value) {
                      print(
                          'Name field changed: "$value", isValid: $isNameValid, showError: ${!isNameValid && nameController.text.isNotEmpty}');
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: const OutlineInputBorder(),
                      errorText:
                          !isPhoneValid && phoneController.text.isNotEmpty
                              ? 'Phone number must be at least 6 digits'
                              : null,
                    ),
                    keyboardType: TextInputType.phone,
                    onChanged: (value) {
                      print(
                          'Register Phone field changed: "$value", isValid: $isPhoneValid, showError: ${!isPhoneValid && phoneController.text.isNotEmpty}');
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: onTogglePasswordVisibility,
                      ),
                    ),
                    obscureText: obscurePassword,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                          isSubmitting ? 'Please wait...' : 'Create account'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account?'),
                      TextButton(
                        onPressed: onSwitchToLogin,
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  final bool isLogin;
  const _AuthHeader({required this.isLogin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLogin
                  ? Icons.lock_open_rounded
                  : Icons.person_add_alt_1_rounded,
              color: Colors.blue.shade700,
              size: 34,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isLogin ? 'Welcome back' : 'Create account',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            isLogin ? 'Login to continue' : 'Sign up to get started',
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _SegmentedSwitch extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const _SegmentedSwitch({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _SegButton(
            text: 'Login',
            selected: selectedIndex == 0,
            onTap: () => onSelect(0),
          ),
          _SegButton(
            text: 'Register',
            selected: selectedIndex == 1,
            onTap: () => onSelect(1),
          ),
        ],
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _SegButton(
      {required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.blue.shade800 : Colors.blueGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
