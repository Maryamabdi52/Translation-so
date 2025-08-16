import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../services/voice_recording_service.dart';
import 'auth_screen.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  late final AudioPlayer _audioPlayer;
  List<VoiceRecording> _recordings = [];
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String? _currentlyPlayingId;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _loadRecordings();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadRecordings() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      if (!isLoggedIn) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
        return;
      }

      setState(() => _isLoggedIn = true);

      final recordingsData = await VoiceRecordingService.getRecordings();
      final recordings =
          recordingsData.map((json) => VoiceRecording.fromJson(json)).toList();

      if (mounted) {
        setState(() {
          _recordings = recordings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load recordings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _playRecording(VoiceRecording recording) async {
    try {
      // Stop any currently playing audio
      await _audioPlayer.stop();

      setState(() {
        _currentlyPlayingId = recording.id;
      });

      // Fetch audio data from API
      final audioDataResponse =
          await VoiceRecordingService.getAudioData(recording.id);
      final audioData = audioDataResponse['audio_data'] as String;

      if (audioData.isEmpty) {
        throw Exception('No audio data available for this recording');
      }

      // Convert base64 audio data to bytes
      final audioBytes = VoiceRecordingService.base64ToAudio(audioData);

      // Create a proper WAV file from the raw audio data
      final wavBytes = _createWavFile(audioBytes, sampleRate: 8000);

      // Create a temporary WAV file to play the audio
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/recording_${recording.id}.wav');
      await tempFile.writeAsBytes(wavBytes);

      // Play the audio file with increased volume
      await _audioPlayer.play(DeviceFileSource(tempFile.path));
      await _audioPlayer.setVolume(1.0); // Set volume to maximum (1.0 = 100%)

      // Listen for playback completion
      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.completed) {
          if (mounted) {
            setState(() {
              _currentlyPlayingId = null;
            });
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.play_arrow, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Playing: "${recording.transcription}"'),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _currentlyPlayingId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _currentlyPlayingId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playback stopped'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to stop playback: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Create a proper WAV file from raw audio bytes with amplified volume
  Uint8List _createWavFile(Uint8List audioBytes, {int sampleRate = 8000}) {
    // Amplify the audio data to make it louder
    final Uint8List amplifiedAudio = Uint8List(audioBytes.length);
    const double amplificationFactor = 3.0; // Increase volume by 3x

    for (int i = 0; i < audioBytes.length; i++) {
      // Convert byte to signed value (-128 to 127)
      int sample = audioBytes[i] - 128;

      // Amplify the sample
      sample = (sample * amplificationFactor).round();

      // Clamp to valid range (-128 to 127)
      sample = sample.clamp(-128, 127);

      // Convert back to unsigned byte (0 to 255)
      amplifiedAudio[i] = sample + 128;
    }

    // WAV file header structure
    final int dataSize = amplifiedAudio.length;
    final int fileSize = 36 + dataSize;

    final ByteData header = ByteData(44);

    // RIFF header
    header.setUint32(0, 0x52494646, Endian.big); // "RIFF"
    header.setUint32(4, fileSize, Endian.little); // File size
    header.setUint32(8, 0x57415645, Endian.big); // "WAVE"

    // fmt chunk
    header.setUint32(12, 0x666D7420, Endian.big); // "fmt "
    header.setUint32(16, 16, Endian.little); // fmt chunk size
    header.setUint16(20, 1, Endian.little); // Audio format (PCM)
    header.setUint16(22, 1, Endian.little); // Number of channels (mono)
    header.setUint32(24, sampleRate, Endian.little); // Sample rate
    header.setUint32(28, sampleRate * 1, Endian.little); // Byte rate
    header.setUint16(32, 1, Endian.little); // Block align
    header.setUint16(34, 8, Endian.little); // Bits per sample

    // data chunk
    header.setUint32(36, 0x64617461, Endian.big); // "data"
    header.setUint32(40, dataSize, Endian.little); // Data size

    // Combine header and amplified audio data
    final Uint8List wavFile = Uint8List(44 + dataSize);
    wavFile.setRange(0, 44, header.buffer.asUint8List());
    wavFile.setRange(44, 44 + dataSize, amplifiedAudio);

    return wavFile;
  }

  Future<void> _toggleFavorite(VoiceRecording recording) async {
    try {
      await VoiceRecordingService.toggleFavorite(recording.id);
      await _loadRecordings(); // Reload to get updated data
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle favorite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteRecording(VoiceRecording recording) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording'),
        content: Text(
            'Are you sure you want to delete "${recording.transcription}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await VoiceRecordingService.deleteRecording(recording.id);
        await _loadRecordings(); // Reload to get updated data
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recording deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete recording: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _clearAllRecordings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Recordings'),
        content: const Text(
            'Are you sure you want to delete all recordings? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await VoiceRecordingService.clearAllRecordings();
        await _loadRecordings(); // Reload to get updated data
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All recordings cleared successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear recordings: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _ensureLoggedIn() async {
    if (_isLoggedIn) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );

    if (result == true) {
      await _loadRecordings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Voice Recordings'),
        backgroundColor: Colors.blue,
        actions: [
          if (_recordings.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAllRecordings,
              tooltip: 'Clear all recordings',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecordings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isLoggedIn
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Login required to view recordings',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _ensureLoggedIn,
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                )
              : _recordings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mic_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No recordings yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Use the microphone in the translation screen to create recordings',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _recordings.length,
                      itemBuilder: (context, index) {
                        final recording = _recordings[index];
                        final isPlaying = _currentlyPlayingId == recording.id;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  isPlaying ? Colors.green : Colors.blue,
                              child: Icon(
                                isPlaying ? Icons.pause : Icons.mic,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              recording.transcription.isNotEmpty
                                  ? recording.transcription
                                  : 'Voice Recording',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Duration: ${recording.duration.toStringAsFixed(1)}s',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  'Language: ${recording.language}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '${recording.timestamp.toLocal().toString().split('.')[0]}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isPlaying ? Icons.stop : Icons.play_arrow,
                                    color:
                                        isPlaying ? Colors.red : Colors.green,
                                  ),
                                  onPressed: () {
                                    if (isPlaying) {
                                      _stopPlayback();
                                    } else {
                                      _playRecording(recording);
                                    }
                                  },
                                  tooltip: isPlaying ? 'Stop' : 'Play',
                                ),
                                IconButton(
                                  icon: Icon(
                                    recording.isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: recording.isFavorite
                                        ? Colors.red
                                        : null,
                                  ),
                                  onPressed: () => _toggleFavorite(recording),
                                  tooltip: recording.isFavorite
                                      ? 'Remove from favorites'
                                      : 'Add to favorites',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteRecording(recording),
                                  tooltip: 'Delete recording',
                                ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
    );
  }
}
