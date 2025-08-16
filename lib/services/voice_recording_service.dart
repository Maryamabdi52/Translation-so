import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service class for handling voice recording operations with the backend API
class VoiceRecordingService {
  static const String baseUrl = 'http://127.0.0.1:5000';

  /// Get authentication token from SharedPreferences
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Get headers with authentication token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Save a voice recording to the backend
  ///
  /// [audioData] - Base64 encoded audio data or data URL
  /// [duration] - Duration of recording in seconds
  /// [language] - Language of the speech (default: 'Somali')
  /// [transcription] - Text transcription (required)
  /// [translation] - Optional translation
  static Future<Map<String, dynamic>> saveRecording({
    required String audioData,
    required double duration,
    String language = 'Somali',
    required String transcription,
    String translation = '',
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/voice/save');
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'audio_data': audioData,
          'duration': duration,
          'language': language,
          'transcription': transcription,
          'translation': translation,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to save recording');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get all voice recordings for the current user
  static Future<List<Map<String, dynamic>>> getRecordings() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/voice/recordings');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get recordings');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get a specific voice recording by ID
  static Future<Map<String, dynamic>> getRecording(String recordingId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/voice/recordings/$recordingId');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get recording');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Update a voice recording (translation, favorite status)
  static Future<Map<String, dynamic>> updateRecording({
    required String recordingId,
    String? translation,
    bool? isFavorite,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/voice/recordings/$recordingId');

      final Map<String, dynamic> updateData = {};
      if (translation != null) updateData['translation'] = translation;
      if (isFavorite != null) updateData['is_favorite'] = isFavorite;

      final response = await http.put(
        url,
        headers: headers,
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update recording');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get audio data as base64 for playback
  static Future<Map<String, dynamic>> getAudioData(String recordingId) async {
    try {
      final headers = await _getHeaders();
      final url =
          Uri.parse('$baseUrl/voice/recordings/$recordingId/audio-data');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get audio data');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Stream audio file (returns audio bytes)
  static Future<Uint8List> streamAudio(String recordingId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/voice/recordings/$recordingId/audio');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to stream audio');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Download voice recording as attachment
  static Future<Uint8List> downloadRecording(String recordingId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/voice/recordings/$recordingId/download');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to download recording');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Save voice recording to local file system (server-side)
  static Future<Map<String, dynamic>> saveRecordingLocal(
      String recordingId) async {
    try {
      final headers = await _getHeaders();
      final url =
          Uri.parse('$baseUrl/voice/recordings/$recordingId/save-local');
      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['error'] ?? 'Failed to save recording locally');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Toggle favorite status of a voice recording
  static Future<Map<String, dynamic>> toggleFavorite(String recordingId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/voice/recordings/$recordingId/favorite');
      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to toggle favorite');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get all favorite voice recordings
  static Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/voice/favorites');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get favorites');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Delete a voice recording
  static Future<void> deleteRecording(String recordingId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/voice/recordings/$recordingId');
      final response = await http.delete(url, headers: headers);

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to delete recording');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Delete all voice recordings for the current user
  static Future<Map<String, dynamic>> clearAllRecordings() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/voice/recordings');
      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to clear recordings');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Convert audio bytes to base64 string
  static String audioToBase64(Uint8List audioBytes) {
    return base64Encode(audioBytes);
  }

  /// Convert base64 string back to audio bytes
  static Uint8List base64ToAudio(String base64String) {
    return base64Decode(base64String);
  }

  /// Parse data URL audio format
  /// data_url: 'data:audio/webm;codecs=opus;base64,AAAA...'
  /// return: (mime_type, raw_base64)
  static Map<String, String>? parseDataUrlAudio(String dataUrl) {
    if (!dataUrl.startsWith("data:")) {
      return null;
    }

    final parts = dataUrl.split(",");
    if (parts.length != 2) {
      return null;
    }

    final header = parts[0];
    final b64 = parts[1];

    if (!header.contains(";base64")) {
      return null;
    }

    final mimeType = header.split(";")[0].substring(5); // Remove "data:" prefix
    return {
      'mime_type': mimeType,
      'base64': b64,
    };
  }
}

/// Model class for voice recording data
class VoiceRecording {
  final String id;
  final String userId;
  final String? fileId;
  final String? filename;
  final String? mimeType;
  final int? sizeBytes;
  final double duration;
  final String language;
  final String transcription;
  final String translation;
  final DateTime timestamp;
  final bool isFavorite;

  VoiceRecording({
    required this.id,
    required this.userId,
    this.fileId,
    this.filename,
    this.mimeType,
    this.sizeBytes,
    required this.duration,
    required this.language,
    required this.transcription,
    required this.translation,
    required this.timestamp,
    required this.isFavorite,
  });

  /// Create VoiceRecording from JSON data
  factory VoiceRecording.fromJson(Map<String, dynamic> json) {
    return VoiceRecording(
      id: json['_id'] ?? '',
      userId: json['user_id'] ?? '',
      fileId: json['file_id'],
      filename: json['filename'],
      mimeType: json['mime_type'],
      sizeBytes: json['size_bytes'],
      duration: (json['duration'] ?? 0).toDouble(),
      language: json['language'] ?? 'Somali',
      transcription: json['transcription'] ?? '',
      translation: json['translation'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      isFavorite: json['is_favorite'] ?? false,
    );
  }

  /// Convert VoiceRecording to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user_id': userId,
      'file_id': fileId,
      'filename': filename,
      'mime_type': mimeType,
      'size_bytes': sizeBytes,
      'duration': duration,
      'language': language,
      'transcription': transcription,
      'translation': translation,
      'timestamp': timestamp.toIso8601String(),
      'is_favorite': isFavorite,
    };
  }

  /// Create a copy with updated fields
  VoiceRecording copyWith({
    String? id,
    String? userId,
    String? fileId,
    String? filename,
    String? mimeType,
    int? sizeBytes,
    double? duration,
    String? language,
    String? transcription,
    String? translation,
    DateTime? timestamp,
    bool? isFavorite,
  }) {
    return VoiceRecording(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fileId: fileId ?? this.fileId,
      filename: filename ?? this.filename,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      duration: duration ?? this.duration,
      language: language ?? this.language,
      transcription: transcription ?? this.transcription,
      translation: translation ?? this.translation,
      timestamp: timestamp ?? this.timestamp,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
