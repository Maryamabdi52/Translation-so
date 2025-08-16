# Translation App

A Flutter application for translating between Somali and English with voice recording capabilities.

## Features

### Translation
- Text translation between Somali and English
- Speech-to-text input for hands-free translation
- Copy and share translated text
- Save translations as favorites (requires login)

### Speech-to-Text Translation
- **NEW**: Enhanced speech recognition for translation
- Speak in Somali and get instant text transcription
- Automatic translation of transcribed speech
- Save transcribed text to history and favorites
- Visual feedback during speech recognition
- Login required for saving transcriptions

### User Management
- User registration and login
- Secure authentication with tokens
- User-specific favorites and history
- Guest mode for basic translation

### Settings
- Dark/Light theme toggle
- Adjustable text size
- Keyboard startup preference

## Speech-to-Text Features

### Speech Recognition Process
1. **Microphone Permission**: App requests microphone permission
2. **Speech Input**: Speak in Somali for instant transcription
3. **Automatic Translation**: Transcribed text is automatically translated
4. **History & Favorites**: Transcribed text is saved to history and can be favorited
5. **Visual Feedback**: 
   - Microphone button changes during recognition
   - Success notifications with transcription details
   - Option to mark as favorite immediately

### Speech Recognition Management
- **Automatic Saving**: All speech transcriptions are saved to history
- **Translation Integration**: Transcribed text is automatically translated
- **Favorites**: Mark important transcriptions as favorites
- **History**: View all speech transcriptions in history
- **Login Required**: Full features require user authentication

### Technical Details
- Speech recognition: Google Speech-to-Text API
- Language: Somali (so-SO)
- Translation: Google Translate API
- Storage: Backend API with user authentication
- Real-time transcription and translation

## Getting Started

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run the App**:
   ```bash
   flutter run
   ```

3. **Speech Recognition Usage**:
   - Tap the microphone button in the translation screen
   - Speak in Somali for instant transcription
   - Text is automatically translated to English
   - Transcribed text is saved to history
   - Mark important transcriptions as favorites
   - Login required for saving transcriptions

## Dependencies

- `flutter`: Core framework
- `http`: API communication
- `shared_preferences`: Local storage
- `speech_to_text`: Speech recognition
- `record`: Audio recording
- `audioplayers`: Audio playback
- `path_provider`: File system access
- `timeago`: Time formatting
- `share_plus`: Text sharing

## Backend API

The app connects to a backend API for:
- User authentication
- Translation services
- Voice recording storage
- Favorites management
- History tracking

## Permissions

- **Microphone**: Required for voice recording and speech recognition
- **Storage**: For temporary audio files
- **Network**: For API communication

## Troubleshooting

### Voice Recording Issues
1. **Permission Denied**: Grant microphone permission in app settings
2. **No Audio**: Check device volume and microphone functionality
3. **Recording Fails**: Ensure stable internet connection for backend API
4. **Playback Issues**: Verify audio file integrity and format support

### Translation Issues
1. **Network Errors**: Check internet connection
2. **Authentication**: Login required for full features
3. **Speech Recognition**: Ensure clear speech and quiet environment

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.
