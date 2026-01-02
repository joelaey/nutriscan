/// API Configuration
/// This file reads API keys from environment variables (preferred for security)
/// 
/// Build with: flutter build appbundle --dart-define=GEMINI_API_KEY=your_key_here
/// 
/// For local development, you can create lib/config/api_keys.dart (gitignored):
/// ```dart
/// class LocalApiKeys {
///   static const String geminiApiKey = 'YOUR_API_KEY_HERE';
/// }
/// ```
/// Then import it here and update the defaultValue.

class ApiConfig {
  /// Gemini API Key - loaded from environment variable
  /// Pass via: --dart-define=GEMINI_API_KEY=your_key_here
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '', // Will fail gracefully if not set - use dart-define in build
  );
  
  /// Gemini API Base URL
  static const String geminiBaseUrl = 
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  
  /// Check if API key is configured
  static bool get isConfigured => geminiApiKey.isNotEmpty;
}
