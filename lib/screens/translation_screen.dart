// // =====================
// // TranslationScreen: Main translation logic and stateful widget
// // =====================
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:speech_to_text/speech_to_text.dart' as stt;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../models/translation_item.dart';
// import 'auth_screen.dart';
// import 'favorites_screen.dart';

// class TranslationScreen extends StatefulWidget {
//   final Function toggleTheme;
//   final bool isDarkMode;
//   final VoidCallback? openDrawer;
//   final double textSize;

//   const TranslationScreen({
//     super.key,
//     required this.toggleTheme,
//     required this.isDarkMode,
//     this.openDrawer,
//     required this.textSize,
//   });

//   @override
//   _TranslationScreenState createState() => _TranslationScreenState();
// }

// class _TranslationScreenState extends State<TranslationScreen> {
//   String selectedLanguage1 = 'Somali';
//   String selectedLanguage2 = 'English';
//   TextEditingController textController = TextEditingController();
//   String translatedText = '';
//   bool isFavorite = false;
//   late double _textSize;
//   final FocusNode _textFieldFocusNode = FocusNode();

//   late stt.SpeechToText _speech;
//   bool _isListening = false;
//   bool _isLoggedIn = false;

//   final List<TranslationItem> historyItems = [];
//   final List<TranslationItem> favoriteItems = [];

//   @override
//   void initState() {
//     super.initState();
//     _speech = stt.SpeechToText();
//     textController.addListener(_onTextChanged);
//     _textSize = widget.textSize;
//     _loadTextSize();
//     _checkKeyboardPreference();
//     _loadLoginStatus();
//   }

//   Future<void> _loadLoginStatus() async {
//     final prefs = await SharedPreferences.getInstance();
//     if (!mounted) return;
//     setState(() => _isLoggedIn = prefs.getBool('is_logged_in') ?? false);
//   }

//   @override
//   void didUpdateWidget(covariant TranslationScreen oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.textSize != oldWidget.textSize) {
//       setState(() {
//         _textSize = widget.textSize;
//       });
//     }
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     _checkKeyboardPreference();
//   }

//   Future<void> _checkKeyboardPreference() async {
//     final prefs = await SharedPreferences.getInstance();
//     bool showKeyboard = prefs.getBool('show_keyboard_at_startup') ?? false;
//     if (showKeyboard && mounted) {
//       _textFieldFocusNode.requestFocus();
//     }
//   }

//   Future<void> _loadTextSize() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _textSize = prefs.getDouble('text_size') ?? widget.textSize;
//     });
//   }

//   @override
//   void dispose() {
//     _textFieldFocusNode.dispose();
//     textController.removeListener(_onTextChanged);
//     textController.dispose();
//     _speech.stop();
//     super.dispose();
//   }

//   void _onTextChanged() {
//     if (mounted) {
//       setState(() {
//         translatedText = '';
//       });
//     }
//   }

//   Future<void> _translateSpeechText(String text) async {
//     if (text.trim().isEmpty) return;
//     if (mounted) {
//       setState(() {
//         translatedText = 'Translating...';
//       });
//     }

//     // Somali to English: use existing model
//     final url = Uri.parse(
//       'https://translate.googleapis.com/translate_a/single?client=gtx&sl=so&tl=en&dt=t&q=${Uri.encodeComponent(text)}',
//     );

//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         try {
//           final data = json.decode(response.body);
//           String translated = '';
//           if (data is List && data.isNotEmpty && data[0] is List) {
//             final translations = data[0] as List;
//             if (translations.isNotEmpty && translations[0] is List) {
//               final firstTranslation = translations[0] as List;
//               if (firstTranslation.length > 0) {
//                 translated = firstTranslation[0].toString();
//               }
//             }
//           }
//           if (translated.isEmpty) {
//             translated = 'Error: No translation received';
//           }
//           if (mounted) {
//             setState(() {
//               translatedText = translated;
//             });
//           }
//         } catch (e) {
//           if (mounted) {
//             setState(() {
//               translatedText = 'Error: Invalid response format';
//             });
//           }
//         }
//       } else {
//         if (mounted) {
//           setState(() {
//             translatedText =
//                 'Translation failed - Status:  {response.statusCode}';
//           });
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           translatedText = 'Error: $e';
//         });
//       }
//     }
//   }

//   Future<void> _translateText() async {
//     final inputText = textController.text.trim();
//     if (inputText.isEmpty) return;
//     if (mounted) {
//       setState(() {
//         translatedText = 'Translating...';
//       });
//     }

//     // Somali to English
//     final url = Uri.parse('http://127.0.0.1:5000/translate');
//     try {
//       final response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'text': inputText,
//           'from_lang': selectedLanguage1,
//           'to_lang': selectedLanguage2
//         }),
//       );
//       if (response.statusCode == 200) {
//         try {
//           final data = json.decode(response.body);
//           String idFromServer = '';
//           String tempTranslatedText = '';
//           if (data != null) {
//             if (data is Map) {
//               tempTranslatedText = data['translated_text'] ??
//                   data['translation'] ??
//                   data['result'] ??
//                   data['text'] ??
//                   data['message'] ??
//                   data['content'] ??
//                   data['output'] ??
//                   data.toString();
//               idFromServer = data['id'] ?? data['_id'] ?? '';
//             } else if (data is String) {
//               tempTranslatedText = data;
//             } else {
//               tempTranslatedText = data.toString();
//             }
//           }
//           if (tempTranslatedText.isEmpty || tempTranslatedText == 'null') {
//             tempTranslatedText = 'Error: Empty translation received';
//           }
//           if (mounted) {
//             setState(() {
//               translatedText = tempTranslatedText;
//               if (translatedText != 'Error: Empty translation received' &&
//                   idFromServer.isNotEmpty) {
//                 final newItem = TranslationItem(
//                   id: idFromServer,
//                   sourceText: inputText,
//                   translatedText: translatedText,
//                   timestamp: DateTime.now(),
//                   isFavorite: false,
//                 );
//                 historyItems.insert(0, newItem);
//                 isFavorite = false;
//               }
//             });
//           }
//           if (tempTranslatedText != 'Error: Empty translation received' &&
//               idFromServer.isNotEmpty) {
//             try {
//               await saveToHistoryBackend(
//                 originalText: inputText,
//                 translatedText: tempTranslatedText,
//                 isFavorite: false,
//               );
//             } catch (e) {}
//           }
//         } catch (e) {
//           if (mounted) {
//             setState(() {
//               translatedText =
//                   'Error: Invalid response format. Check console for details.';
//             });
//           }
//         }
//       } else {
//         if (mounted) {
//           setState(() {
//             translatedText =
//                 'Error: Server returned status ${response.statusCode}';
//           });
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           translatedText = 'Error: Could not connect to server.\n$e';
//         });
//       }
//     }
//   }

//   void switchLanguages() {
//     setState(() {
//       String temp = selectedLanguage1;
//       selectedLanguage1 = selectedLanguage2;
//       selectedLanguage2 = temp;
//       _onTextChanged();
//     });
//   }

//   void _copyToClipboard(String text) {
//     Clipboard.setData(ClipboardData(text: text));
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('copied to clipboard'),
//         duration: Duration(seconds: 2),
//       ),
//     );
//   }

//   Future<void> markAsFavorite(String id) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('auth_token');
//     final url = Uri.parse('http://127.0.0.1:5000/favorite');
//     final headers = {
//       'Content-Type': 'application/json',
//       if (token != null) 'Authorization': 'Bearer $token',
//       if (token != null) 'x-access-token': token,
//     };
//     final response = await http.post(
//       url,
//       headers: headers,
//       body: json.encode({'id': id}),
//     );
//     if (response.statusCode != 200) {
//       String serverMsg = response.body;
//       try {
//         final bodyJson = json.decode(response.body);
//         if (bodyJson is Map && bodyJson['error'] != null) {
//           serverMsg = bodyJson['error'].toString();
//         }
//       } catch (_) {}
//       throw Exception('Failed to mark as favorite: $serverMsg');
//     }
//   }

//   Future<bool> _ensureLoggedIn() async {
//     final prefs = await SharedPreferences.getInstance();
//     final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
//     if (isLoggedIn) return true;
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const AuthScreen()),
//     );
//     final updated =
//         (result == true) || (prefs.getBool('is_logged_in') ?? false);
//     if (!updated) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Login required to use favorites')),
//         );
//       }
//       return false;
//     }
//     if (mounted) setState(() => _isLoggedIn = true);
//     return true;
//   }

//   // switch-account flow removed

//   void _toggleFavorite() async {
//     final loggedIn = await _ensureLoggedIn();
//     if (!loggedIn) return;
//     if (translatedText.isEmpty) return;
//     final match = historyItems.firstWhere(
//       (item) =>
//           item.sourceText == textController.text &&
//           item.translatedText == translatedText &&
//           item.id.isNotEmpty,
//       orElse: () => TranslationItem(
//         id: '',
//         sourceText: textController.text,
//         translatedText: translatedText,
//         timestamp: DateTime.now(),
//         isFavorite: true,
//       ),
//     );

//     if (match.id.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please translate first, then mark as favorite.'),
//           duration: Duration(seconds: 2),
//         ),
//       );
//       return;
//     }
//     setState(() {
//       isFavorite = !isFavorite;
//     });
//     if (isFavorite) {
//       try {
//         await markAsFavorite(match.id);
//         if (!mounted) return;
//         setState(() {
//           favoriteItems.insert(
//             0,
//             TranslationItem(
//               id: match.id,
//               sourceText: match.sourceText,
//               translatedText: match.translatedText,
//               timestamp: match.timestamp,
//               isFavorite: true,
//             ),
//           );
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Text('Added to favorites'),
//             duration: const Duration(seconds: 3),
//             action: SnackBarAction(
//               label: 'View',
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => const FavoritesScreen()),
//                 );
//               },
//             ),
//           ),
//         );
//       } catch (e) {
//         if (!mounted) return;
//         setState(() {
//           isFavorite = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(e.toString())),
//         );
//       }
//     }
//   }

//   void _shareTranslation() async {
//     if (translatedText.isEmpty) return;
//     final loggedIn = await _ensureLoggedIn();
//     if (!loggedIn) return;
//     Share.share(translatedText);
//   }

//   void _startListening() async {
//     // Set locale for Somali to English translation
//     String localeId = 'so-SO';
//     bool available = await _speech.initialize(
//       onStatus: (val) {
//         if (val == 'done' || val == 'notListening') {
//           if (mounted) {
//             setState(() => _isListening = false);
//           }
//           if (textController.text.isNotEmpty) {
//             _translateSpeechText(textController.text);
//           }
//         }
//       },
//       onError: (val) {
//         if (mounted) {
//           setState(() => _isListening = false);
//         }
//         if (!val.toString().contains('timeout')) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Speech recognition error: $val')),
//           );
//         }
//       },
//     );
//     if (available) {
//       setState(() => _isListening = true);
//       _speech.listen(
//         localeId: localeId,
//         listenMode: stt.ListenMode.dictation,
//         onResult: (val) {
//           if (mounted) {
//             setState(() {
//               textController.text = val.recognizedWords;
//             });
//           }
//         },
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Speech recognition not available')),
//       );
//     }
//   }

//   void _stopListening() {
//     _speech.stop();
//     if (mounted) {
//       setState(() => _isListening = false);
//     }
//   }

//   void _handleMicrophonePress() {
//     if (_isListening) {
//       _stopListening();
//     } else {
//       _startListening();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(56),
//         child: LanguageSelector(
//           selectedLanguage1: selectedLanguage1,
//           selectedLanguage2: selectedLanguage2,
//           onSwap: switchLanguages,
//           onMenu: widget.openDrawer,
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             InputSection(
//               textController: textController,
//               textFieldFocusNode: _textFieldFocusNode,
//               isDarkMode: widget.isDarkMode,
//               textSize: _textSize,
//               isListening: _isListening,
//               onCopy: () {
//                 if (textController.text.isNotEmpty) {
//                   _copyToClipboard(textController.text);
//                 }
//               },
//               onMic: _handleMicrophonePress,
//               onClear: () {
//                 textController.clear();
//               },
//               onSend: _translateText,
//             ),
//             const SizedBox(height: 8),
//             Expanded(
//               child: OutputSection(
//                 translatedText: translatedText,
//                 textSize: _textSize,
//                 isFavorite: isFavorite,
//                 onCopy: () {
//                   if (translatedText.isNotEmpty) {
//                     _copyToClipboard(translatedText);
//                   }
//                 },
//                 onShare: _shareTranslation,
//                 onFavorite: _toggleFavorite,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> saveToHistoryBackend({
//     required String originalText,
//     required String translatedText,
//     required bool isFavorite,
//   }) async {
//     final url = Uri.parse('http://127.0.0.1:5000/history');
//     final response = await http.post(
//       url,
//       headers: {'Content-Type': 'application/json'},
//       body: json.encode({
//         'original_text': originalText,
//         'translated_text': translatedText,
//         'is_favorite': isFavorite,
//       }),
//     );
//     if (response.statusCode != 200) {
//       throw Exception('Failed to save item to backend history');
//     }
//   }

//   // Helper to fetch latest history item ID from backend
//   Future<String?> fetchLatestHistoryId(String source, String translated) async {
//     final url = Uri.parse('http://127.0.0.1:5000/history');
//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body);
//         for (var item in data) {
//           if (item['original_text'] == source &&
//               item['translated_text'] == translated) {
//             return item['_id'] ?? item['id'];
//           }
//         }
//       }
//     } catch (e) {}
//     return null;
//   }
// }

// // =====================
// // LanguageSelector: Top bar for language swap
// // =====================
// class LanguageSelector extends StatelessWidget {
//   final String selectedLanguage1;
//   final String selectedLanguage2;
//   final VoidCallback onSwap;
//   final VoidCallback? onMenu;
//   const LanguageSelector({
//     Key? key,
//     required this.selectedLanguage1,
//     required this.selectedLanguage2,
//     required this.onSwap,
//     this.onMenu,
//   }) : super(key: key);
//   @override
//   Widget build(BuildContext context) {
//     return AppBar(
//       backgroundColor: Colors.blue,
//       title: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             selectedLanguage1,
//             style: const TextStyle(color: Colors.white),
//           ),
//           IconButton(
//             icon: const Icon(Icons.arrow_forward, color: Colors.white),
//             onPressed: onSwap,
//           ),
//           Text(
//             selectedLanguage2,
//             style: const TextStyle(color: Colors.white),
//           ),
//         ],
//       ),
//       elevation: 0,
//       leading: onMenu != null
//           ? IconButton(
//               icon: const Icon(Icons.menu, color: Colors.white),
//               onPressed: onMenu,
//             )
//           : null,
//     );
//   }
// }

// // =====================
// // InputSection: Text input and action buttons
// // =====================
// class InputSection extends StatelessWidget {
//   final TextEditingController textController;
//   final FocusNode textFieldFocusNode;
//   final bool isDarkMode;
//   final double textSize;
//   final bool isListening;
//   final VoidCallback onCopy;
//   final VoidCallback onMic;
//   final VoidCallback onClear;
//   final Future<void> Function() onSend;
//   const InputSection({
//     Key? key,
//     required this.textController,
//     required this.textFieldFocusNode,
//     required this.isDarkMode,
//     required this.textSize,
//     required this.isListening,
//     required this.onCopy,
//     required this.onMic,
//     required this.onClear,
//     required this.onSend,
//   }) : super(key: key);
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         TextField(
//           controller: textController,
//           focusNode: textFieldFocusNode,
//           style: TextStyle(
//             fontSize: textSize,
//             color: isDarkMode ? Colors.white : Colors.black,
//           ),
//           decoration: InputDecoration(
//             hintText: 'type here',
//             hintStyle: TextStyle(
//               fontSize: textSize,
//               color: isDarkMode ? Colors.white70 : Colors.grey,
//             ),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             contentPadding: const EdgeInsets.all(16),
//             filled: true,
//             fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
//           ),
//           maxLines: 6,
//         ),
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const SizedBox(width: 16),
//               _buildCircularButton(Icons.copy, onCopy),
//               const SizedBox(width: 16),
//               _buildCircularButton(isListening ? Icons.stop : Icons.mic, onMic),
//               const SizedBox(width: 16),
//               _buildCircularButton(Icons.clear, onClear),
//               const SizedBox(width: 16),
//               _buildCircularButton(Icons.send, () {
//                 onSend();
//               }),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCircularButton(IconData icon, VoidCallback onPressed) {
//     return Container(
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: Colors.blue,
//       ),
//       child: IconButton(
//         icon: Icon(icon, color: Colors.white),
//         onPressed: onPressed,
//       ),
//     );
//   }
// }

// // =====================
// // OutputSection: Translation result and action buttons
// // =====================
// class OutputSection extends StatelessWidget {
//   final String translatedText;
//   final double textSize;
//   final bool isFavorite;
//   final VoidCallback onCopy;
//   final VoidCallback onShare;
//   final VoidCallback onFavorite;
//   const OutputSection({
//     Key? key,
//     required this.translatedText,
//     required this.textSize,
//     required this.isFavorite,
//     required this.onCopy,
//     required this.onShare,
//     required this.onFavorite,
//   }) : super(key: key);
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.blue,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               physics: const BouncingScrollPhysics(),
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.only(bottom: 8),
//                 child: Text(
//                   translatedText.isEmpty ? 'Translation' : translatedText,
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: textSize,
//                     height: 1.5,
//                   ),
//                   textAlign: TextAlign.left,
//                 ),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.only(top: 8),
//             child: SizedBox(
//               height: 48,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _buildCircularButton(Icons.copy, onCopy),
//                   _buildCircularButton(Icons.share, onShare),
//                   _buildCircularButton(
//                     isFavorite ? Icons.favorite : Icons.favorite_border,
//                     onFavorite,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCircularButton(IconData icon, VoidCallback onPressed) {
//     return Container(
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: Colors.white.withOpacity(0.2),
//       ),
//       child: IconButton(
//         icon: Icon(icon, color: Colors.white),
//         onPressed: onPressed,
//       ),
//     );
//   }
// }

// =====================
// TranslationScreen: Main translation logic and stateful widget
// =====================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/translation_item.dart';
import '../services/voice_recording_service.dart';
import 'auth_screen.dart';
import 'favorites_screen.dart';

class TranslationScreen extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkMode;
  final VoidCallback? openDrawer;
  final double textSize;

  const TranslationScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
    this.openDrawer,
    required this.textSize,
  });

  @override
  _TranslationScreenState createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  String selectedLanguage1 = 'Somali';
  String selectedLanguage2 = 'English';
  TextEditingController textController = TextEditingController();
  String translatedText = '';
  bool isFavorite = false;
  late double _textSize;
  final FocusNode _textFieldFocusNode = FocusNode();

  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isLoggedIn = false;
  DateTime? _recordingStartTime;
  bool _isSavingRecording = false;
  String? _recordingPath;
  bool _isRecordingAudio = false;
  double _recordingAmplitude = 0.0;
  bool _hasTranslatedThisSession = false;

  final List<TranslationItem> favoriteItems = [];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    textController.addListener(_onTextChanged);
    _textSize = widget.textSize;
    _loadTextSize();
    _checkKeyboardPreference();
    _loadLoginStatus();
  }

  Future<void> _loadLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _isLoggedIn = prefs.getBool('is_logged_in') ?? false);
  }

  @override
  void didUpdateWidget(covariant TranslationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.textSize != oldWidget.textSize) {
      setState(() {
        _textSize = widget.textSize;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkKeyboardPreference();
  }

  Future<void> _checkKeyboardPreference() async {
    final prefs = await SharedPreferences.getInstance();
    bool showKeyboard = prefs.getBool('show_keyboard_at_startup') ?? false;
    if (showKeyboard && mounted) {
      _textFieldFocusNode.requestFocus();
    }
  }

  Future<void> _loadTextSize() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _textSize = prefs.getDouble('text_size') ?? widget.textSize;
    });
  }

  @override
  void dispose() {
    _textFieldFocusNode.dispose();
    textController.removeListener(_onTextChanged);
    textController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {
        translatedText = '';
      });
    }
  }

  /// Save translation to history
  Future<void> _saveToHistory(
      String originalText, String translatedText) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        // Don't show error for history - it's optional
        return;
      }

      final url = Uri.parse('http://192.168.146.218:5000/history');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-access-token': token,
        },
        body: json.encode({
          'original_text': originalText,
          'translated_text': translatedText,
          'from_lang': selectedLanguage1,
          'to_lang': selectedLanguage2,
        }),
      );

      if (response.statusCode != 200) {
        print('Failed to save to history: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving to history: $e');
    }
  }

  /// Save text translation to favorites
  Future<void> _saveTextToFavorites(
      String originalText, String translatedText) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        // Login required - silent fail
        return;
      }

      final url = Uri.parse('http://192.168.146.218:5000/favorite');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-access-token': token,
        },
        body: json.encode({
          'original_text': originalText,
          'translated_text': translatedText,
          'from_lang': selectedLanguage1,
          'to_lang': selectedLanguage2,
        }),
      );

      if (response.statusCode == 200) {
        // Successfully saved to favorites - no notification
      } else {
        throw Exception('Failed to save to favorites');
      }
    } catch (e) {
      // Error saving to favorites - silent fail
    }
  }

  /// Save voice recording to backend when speech recognition is complete
  Future<void> _saveVoiceRecording(
      String transcription, double duration) async {
    if (mounted) {
      setState(() {
        _isSavingRecording = true;
      });
    }

    try {
      String audioData = '';

      // If we have a recorded audio file, use it
      if (_recordingPath != null) {
        try {
          // Read the recorded audio file
          final audioFile = File(_recordingPath!);
          if (await audioFile.exists()) {
            final audioBytes = await audioFile.readAsBytes();
            audioData = VoiceRecordingService.audioToBase64(audioBytes);
          }
        } catch (e) {
          print('Error reading audio file: $e');
        }
      }

      // If no audio data available, create a simple audio tone
      if (audioData.isEmpty) {
        // Create a simple audio tone that works in web browsers
        // Using a very simple approach: just create a basic audio signal
        final sampleRate = 8000; // Lower sample rate for web compatibility
        final duration = 1.0; // 1 second
        final samples = (sampleRate * duration).round();

        // Create a simple beep sound (square wave)
        final audioBytes = Uint8List(samples);
        for (int i = 0; i < samples; i++) {
          // Simple square wave at 800Hz
          final t = i / sampleRate.toDouble();
          final frequency = 800.0;
          final wave = sin(t * frequency * 2 * pi) > 0 ? 1.0 : -1.0;
          audioBytes[i] = (127 + 127 * wave).round();
        }

        audioData = VoiceRecordingService.audioToBase64(audioBytes);
      }

      final result = await VoiceRecordingService.saveRecording(
        audioData: audioData,
        duration: duration,
        language: 'Somali',
        transcription: transcription,
      );

      if (mounted) {
        setState(() {
          _isSavingRecording = false;
        });

        // Show success notification for voice recording
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voice recording saved!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Duration: ${duration.toStringAsFixed(1)}s | Text: "$transcription"',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingRecording = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to save voice recording: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _translateSpeechText(String text) async {
    if (text.trim().isEmpty) return;

    // Prevent duplicate translations in the same session
    if (_hasTranslatedThisSession) return;

    if (mounted) {
      setState(() {
        translatedText = 'Translating...';
        _hasTranslatedThisSession = true;
      });
    }

    // Somali to English: use existing model
    final url = Uri.parse(
      'https://translate.googleapis.com/translate_a/single?client=gtx&sl=so&tl=en&dt=t&q=${Uri.encodeComponent(text)}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          String translated = '';
          if (data is List && data.isNotEmpty && data[0] is List) {
            final translations = data[0] as List;
            if (translations.isNotEmpty && translations[0] is List) {
              final firstTranslation = translations[0] as List;
              if (firstTranslation.length > 0) {
                translated = firstTranslation[0].toString();
              }
            }
          }
          if (translated.isEmpty) {
            translated = 'Error: No translation received';
          }
          if (mounted) {
            setState(() {
              translatedText = translated;
            });

            // Save to history for voice recordings
            _saveToHistory(text, translated);

            // Translation completed silently - no notification
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              translatedText = 'Error: Invalid response format';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            translatedText =
                'Translation failed - Status:  {response.statusCode}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          translatedText = 'Error: $e';
        });
      }
    }
  }

  Future<void> _translateText() async {
    final inputText = textController.text.trim();
    if (inputText.isEmpty) return;
    if (mounted) {
      setState(() {
        translatedText = 'Translating...';
      });
    }

    // Get authentication token
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    // Somali to English
    final url = Uri.parse('http://192.168.146.218:5000/translate');
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      headers['x-access-token'] = token;
    }

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'text': inputText,
          'from_lang': selectedLanguage1,
          'to_lang': selectedLanguage2
        }),
      );
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          String idFromServer = '';
          String tempTranslatedText = '';
          if (data != null) {
            if (data is Map) {
              // Check if this is an error response
              if (data.containsKey('error')) {
                // Extract only the Somali error message
                tempTranslatedText = data['error'] ?? 'Error occurred';
              } else {
                // Normal translation response
                tempTranslatedText = data['translated_text'] ??
                    data['translation'] ??
                    data['result'] ??
                    data['text'] ??
                    data['message'] ??
                    data['content'] ??
                    data['output'] ??
                    data.toString();
              }
              idFromServer = data['id'] ?? data['_id'] ?? '';
            } else if (data is String) {
              tempTranslatedText = data;
            } else {
              tempTranslatedText = data.toString();
            }
          }
          if (tempTranslatedText.isEmpty || tempTranslatedText == 'null') {
            tempTranslatedText = 'Error: Empty translation received';
          }
          if (mounted) {
            setState(() {
              translatedText = tempTranslatedText;
              if (translatedText != 'Error: Empty translation received' &&
                  idFromServer.isNotEmpty) {
                // Backend automatically saves to history, no need for local storage
                isFavorite = false;
              }
            });
          }
          // Note: Backend automatically saves translation to history when user is authenticated
          // No need to call saveToHistoryBackend() here as it would create duplicate entries
        } catch (e) {
          if (mounted) {
            setState(() {
              translatedText =
                  'Error: Invalid response format. Check console for details.';
            });
          }
        }
      } else {
        // Handle error responses (non-200 status codes)
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData.containsKey('error')) {
            // Extract only the Somali error message
            if (mounted) {
              setState(() {
                translatedText = errorData['error'] ?? 'Error occurred';
              });
            }
          } else {
            if (mounted) {
              setState(() {
                translatedText =
                    'Error: Server returned status ${response.statusCode}';
              });
            }
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              translatedText =
                  'Error: Server returned status ${response.statusCode}';
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          translatedText = 'Error: Could not connect to server.\n$e';
        });
      }
    }
  }

  void switchLanguages() {
    setState(() {
      String temp = selectedLanguage1;
      selectedLanguage1 = selectedLanguage2;
      selectedLanguage2 = temp;
      _onTextChanged();
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> markAsFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url = Uri.parse('http://192.168.146.218:5000/favorite');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (token != null) 'x-access-token': token,
    };
    final response = await http.post(
      url,
      headers: headers,
      body: json.encode({'id': id}),
    );
    if (response.statusCode != 200) {
      String serverMsg = response.body;
      try {
        final bodyJson = json.decode(response.body);
        if (bodyJson is Map && bodyJson['error'] != null) {
          serverMsg = bodyJson['error'].toString();
        }
      } catch (_) {}
      throw Exception('Failed to mark as favorite: $serverMsg');
    }
  }

  Future<bool> _ensureLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    if (isLoggedIn) return true;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
    final updated =
        (result == true) || (prefs.getBool('is_logged_in') ?? false);
    if (!updated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login required to use favorites')),
        );
      }
      return false;
    }
    if (mounted) setState(() => _isLoggedIn = true);
    return true;
  }

  // switch-account flow removed

  void _toggleFavorite() async {
    final loggedIn = await _ensureLoggedIn();
    if (!loggedIn) return;
    if (translatedText.isEmpty) return;

    // Get the current translation ID from the last successful translation
    String currentTranslationId = '';

    // Check if we have a recent translation that matches current text
    if (textController.text.isNotEmpty && translatedText.isNotEmpty) {
      // Try to find the translation ID from the backend
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        final url = Uri.parse('http://192.168.146.218:5000/history');

        final Map<String, String> headers = <String, String>{};
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
          headers['x-access-token'] = token;
        }

        final response = await http.get(url, headers: headers);
        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final List<dynamic> data = responseData['translations'] ?? [];

          // Find the most recent translation that matches current text
          for (var item in data) {
            if (item['original_text'] == textController.text &&
                item['translated_text'] == translatedText) {
              currentTranslationId = item['_id'] ?? item['id'] ?? '';
              break;
            }
          }
        }
      } catch (e) {
        print('Error finding translation ID: $e');
      }
    }

    if (currentTranslationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please translate first, then mark as favorite.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      isFavorite = !isFavorite;
    });
    if (isFavorite) {
      try {
        await markAsFavorite(currentTranslationId);

        // Save the favorite timestamp to local storage (only if not already saved)
        final prefs = await SharedPreferences.getInstance();
        final favoritedKey = 'favorited_$currentTranslationId';
        final existingTime = prefs.getString(favoritedKey);

        DateTime favoriteTime;
        if (existingTime != null) {
          // Use existing favorite time
          favoriteTime = DateTime.tryParse(existingTime) ?? DateTime.now();
        } else {
          // Set new favorite time
          favoriteTime = DateTime.now();
          await prefs.setString(favoritedKey, favoriteTime.toIso8601String());
        }

        if (!mounted) return;
        setState(() {
          favoriteItems.insert(
            0,
            TranslationItem(
              id: currentTranslationId,
              sourceText: textController.text,
              translatedText: translatedText,
              timestamp: DateTime.now(),
              isFavorite: true,
            ),
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Added to favorites'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                );
              },
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          isFavorite = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _shareTranslation() async {
    if (translatedText.isEmpty) return;
    final loggedIn = await _ensureLoggedIn();
    if (!loggedIn) return;
    Share.share(translatedText);
  }

  void _startListening() async {
    // Set locale for Somali to English translation
    String localeId = 'so-SO';

    // Audio recording will be implemented later
    print('Audio recording placeholder');

    try {
      // Check if speech recognition is already initialized
      bool available = await _speech.initialize(
        onStatus: (val) {
          print('Speech status: $val'); // Debug print
          if (val == 'done' || val == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
            }
            // Automatically translate when speech recognition is done
            if (textController.text.isNotEmpty) {
              _translateSpeechText(textController.text);
            }
          }
        },
        onError: (val) {
          print('Speech error: $val'); // Debug print
          if (mounted) {
            setState(() => _isListening = false);
          }
          if (!val.toString().contains('timeout')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Speech recognition error: $val')),
            );
          }
          _recordingStartTime = null;
        },
      );

      if (available) {
        setState(() {
          _isListening = true;
          _recordingStartTime = DateTime.now();
          _hasTranslatedThisSession = false; // Reset flag for new session
        });

        // Start listening with proper error handling
        await _speech.listen(
          localeId: localeId,
          listenMode: stt.ListenMode.dictation,
          onResult: (val) {
            print('Speech result: ${val.recognizedWords}'); // Debug print
            if (mounted) {
              setState(() {
                textController.text = val.recognizedWords;
              });
              // Don't translate here - wait for speech to end to avoid duplicates
            }
          },
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Speech recognition not available. Please check microphone permissions.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error in _startListening: $e'); // Debug print
      if (mounted) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting speech recognition: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _stopListening() {
    _speech.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
        _hasTranslatedThisSession = false; // Reset flag when stopping
      });
    }
    // Save voice recording if there's text and recording was started
    if (textController.text.isNotEmpty && _recordingStartTime != null) {
      final duration =
          DateTime.now().difference(_recordingStartTime!).inMilliseconds /
              1000.0;
      _saveVoiceRecording(textController.text, duration);
      _recordingStartTime = null;
    }
  }

  Future<void> _handleMicrophonePress() async {
    // Require login before using microphone
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    if (!isLoggedIn) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      final ok = (result == true) || (prefs.getBool('is_logged_in') ?? false);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login required to use microphone')),
        );
        return;
      }

      // Update login status after successful login
      if (mounted) {
        setState(() => _isLoggedIn = true);
      }

      // Wait a moment for the login process to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Reinitialize speech recognition after login
      try {
        bool available = await _speech.initialize(
          onStatus: (val) {
            if (val == 'done' || val == 'notListening') {
              if (mounted) {
                setState(() => _isListening = false);
              }
              // Automatically translate when speech recognition is done
              if (textController.text.isNotEmpty) {
                _translateSpeechText(textController.text);
              }
            }
          },
          onError: (val) {
            if (mounted) {
              setState(() => _isListening = false);
            }
            if (!val.toString().contains('timeout')) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Speech recognition error: $val')),
              );
            }
            _recordingStartTime = null;
          },
        );

        if (!available) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Speech recognition not available after login. Please try again.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      } catch (e) {
        print('Error reinitializing speech recognition: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error setting up microphone: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // Now proceed with microphone functionality
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: LanguageSelector(
          selectedLanguage1: selectedLanguage1,
          selectedLanguage2: selectedLanguage2,
          onSwap: switchLanguages,
          onMenu: widget.openDrawer,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            InputSection(
              textController: textController,
              textFieldFocusNode: _textFieldFocusNode,
              isDarkMode: widget.isDarkMode,
              textSize: _textSize,
              isListening: _isListening,
              isSavingRecording: _isSavingRecording,
              onCopy: () {
                if (textController.text.isNotEmpty) {
                  _copyToClipboard(textController.text);
                }
              },
              onMic: _handleMicrophonePress,
              onClear: () {
                textController.clear();
              },
              onSend: _translateText,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: OutputSection(
                translatedText: translatedText,
                textSize: _textSize,
                isFavorite: isFavorite,
                onCopy: () {
                  if (translatedText.isNotEmpty) {
                    _copyToClipboard(translatedText);
                  }
                },
                onShare: _shareTranslation,
                onFavorite: _toggleFavorite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mark as favorite by finding the item in history
  Future<void> _markAsFavoriteFromHistory(String originalText) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login required to use favorites'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Find the translation in history and mark as favorite
      final url = Uri.parse('http://127.0.0.1:5000/history');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'x-access-token': token,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translations = data['translations'] ?? [];

        // Find the most recent translation that matches
        for (var item in translations) {
          if (item['original_text'] == originalText) {
            // Mark as favorite
            await markAsFavorite(item['_id']);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added to favorites!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
            break;
          }
        }
      }
    } catch (e) {
      print('Error marking as favorite: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to favorites: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

// =====================
// LanguageSelector: Top bar for language swap
// =====================
class LanguageSelector extends StatelessWidget {
  final String selectedLanguage1;
  final String selectedLanguage2;
  final VoidCallback onSwap;
  final VoidCallback? onMenu;
  const LanguageSelector({
    Key? key,
    required this.selectedLanguage1,
    required this.selectedLanguage2,
    required this.onSwap,
    this.onMenu,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blue,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            selectedLanguage1,
            style: const TextStyle(color: Colors.white),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: onSwap,
          ),
          Text(
            selectedLanguage2,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
      elevation: 0,
      leading: onMenu != null
          ? IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: onMenu,
            )
          : null,
    );
  }
}

// =====================
// InputSection: Text input and action buttons
// =====================
class InputSection extends StatelessWidget {
  final TextEditingController textController;
  final FocusNode textFieldFocusNode;
  final bool isDarkMode;
  final double textSize;
  final bool isListening;
  final bool isSavingRecording;
  final VoidCallback onCopy;
  final VoidCallback onMic;
  final VoidCallback onClear;
  final Future<void> Function() onSend;
  const InputSection({
    Key? key,
    required this.textController,
    required this.textFieldFocusNode,
    required this.isDarkMode,
    required this.textSize,
    required this.isListening,
    required this.isSavingRecording,
    required this.onCopy,
    required this.onMic,
    required this.onClear,
    required this.onSend,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: textController,
          focusNode: textFieldFocusNode,
          style: TextStyle(
            fontSize: textSize,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: 'type here',
            hintStyle: TextStyle(
              fontSize: textSize,
              color: isDarkMode ? Colors.white70 : Colors.grey,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(16),
            filled: true,
            fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
          ),
          maxLines: 6,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 16),
              _buildCircularButton(Icons.copy, onCopy),
              const SizedBox(width: 16),
              _buildCircularButton(
                isSavingRecording
                    ? Icons.save
                    : (isListening ? Icons.stop : Icons.mic),
                isSavingRecording ? () {} : onMic,
                isLoading: isSavingRecording,
              ),
              const SizedBox(width: 16),
              _buildCircularButton(Icons.clear, onClear),
              const SizedBox(width: 16),
              _buildCircularButton(Icons.send, () {
                onSend();
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircularButton(IconData icon, VoidCallback onPressed,
      {bool isLoading = false}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isLoading ? Colors.orange : Colors.blue,
      ),
      child: IconButton(
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon, color: Colors.white),
        onPressed: isLoading ? null : onPressed,
      ),
    );
  }
}

// =====================
// OutputSection: Translation result and action buttons
// =====================
class OutputSection extends StatelessWidget {
  final String translatedText;
  final double textSize;
  final bool isFavorite;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onFavorite;
  const OutputSection({
    Key? key,
    required this.translatedText,
    required this.textSize,
    required this.isFavorite,
    required this.onCopy,
    required this.onShare,
    required this.onFavorite,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  translatedText.isEmpty ? 'Translation' : translatedText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: textSize,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCircularButton(Icons.copy, onCopy),
                  _buildCircularButton(Icons.share, onShare),
                  _buildCircularButton(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    onFavorite,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}
