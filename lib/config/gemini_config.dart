import 'gemini_secrets.dart' as gemini_example;

/// Resolves API key: `--dart-define=GEMINI_API_KEY=...` wins, else [kGeminiApiKey] in
/// [gemini_secrets.example.dart]. Optionally copy that file to `gemini_secrets.dart`
/// (gitignored) and change this import to use your untracked file.
String get kGeminiApiKey {
  const fromEnv = String.fromEnvironment('GEMINI_API_KEY');
  if (fromEnv.isNotEmpty) return fromEnv;
  return gemini_example.kGeminiApiKey;
}

/// Multimodal-capable model id for `google_generative_ai` (Google AI Studio / Gemini API).
/// `gemini-2.0-flash` is often disabled for new keys; use a current Flash model instead.
const String kGeminiModelId = 'gemini-2.5-flash';

/// Max attachments per request (MVP guard rail).
const int kGeminiMaxAttachments = 12;

/// Max total bytes of all attachments (20 MB).
const int kGeminiMaxTotalBytes = 20 * 1024 * 1024;
