/// A single turn in a K54 AI conversation. Purely local - the backend
/// (`/k54-ai/v1/chat`) has no server-side persistence at all; `history`
/// is client-supplied on every request and never stored, per the
/// confirmed PHP source (docs/api-audit/ai-assistant.md).
class AiChatMessage {
  final String role; // "user" | "assistant"
  final String content;
  final DateTime timestamp;

  /// True while this assistant message represents a known backend error
  /// state (string-matched, since /chat always returns HTTP 200 - see
  /// AiApiService.chat's doc comment). Lets the UI show a retry
  /// affordance instead of rendering the error text as a normal reply.
  final bool isError;

  AiChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.isError = false,
  });

  bool get isUser => role == "user";

  Map<String, dynamic> toJson() => {
        "role": role,
        "content": content,
        "timestamp": timestamp.toIso8601String(),
      };

  factory AiChatMessage.fromJson(Map<String, dynamic> json) {
    return AiChatMessage(
      role: json["role"] ?? "user",
      content: json["content"] ?? "",
      timestamp: DateTime.tryParse(json["timestamp"] ?? "") ?? DateTime.now(),
    );
  }
}
