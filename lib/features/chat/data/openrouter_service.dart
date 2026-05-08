import 'dart:convert';

import 'package:http/http.dart' as http;

/// Service untuk memanggil OpenRouter Chat Completions API.
class OpenRouterService {
  static const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const _model = 'openai/gpt-oss-120b:free';

  static const _systemPrompt = '''
Kamu adalah Valina AI, asisten kesehatan reproduksi wanita yang ramah dan berpengetahuan.
Kamu HANYA boleh menjawab pertanyaan seputar:
- Menstruasi (siklus, gangguan, tips)
- Ovulasi dan masa subur
- Kesehatan reproduksi wanita
- Kehamilan dan perencanaan keluarga
- PMS dan gejala hormonal
- Kesehatan organ intim wanita

Kalau pengguna bertanya di luar topik tersebut, tolak dengan halus dan arahkan kembali.
Contoh: "Maaf, aku hanya bisa membantu seputar kesehatan reproduksi ya 😊 Ada yang ingin kamu tanyakan soal siklus menstruasi atau kesehatanmu?"

Jawab dalam Bahasa Indonesia, singkat tapi informatif. Gunakan nada hangat dan supportive.
Jangan pernah memberikan diagnosis medis pasti — selalu sarankan konsultasi dokter untuk masalah serius.
''';

  /// Get API key dari --dart-define
  static String get _apiKey {
    const keyFromDefine = String.fromEnvironment('OPENROUTER_API_KEY');
    if (keyFromDefine.isNotEmpty) {
      return keyFromDefine;
    }

    throw Exception(
      'OPENROUTER_API_KEY tidak ditemukan. '
      'Gunakan --dart-define=OPENROUTER_API_KEY=your_key saat build/run.',
    );
  }

  /// Kirim daftar pesan (history) ke API dan dapatkan balasan assistant.
  ///
  /// [messages] adalah list map `{"role": "user"|"assistant", "content": "..."}`.
  /// Return konten balasan assistant sebagai `String`.
  Future<String> sendMessages(List<Map<String, String>> messages) async {
    final body = jsonEncode({
      'model': _model,
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        ...messages,
      ],
    });

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'OpenRouter API error ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Tidak ada respons dari AI.');
    }
    final message = choices[0]['message'] as Map<String, dynamic>;
    return (message['content'] as String?) ?? '';
  }
}
