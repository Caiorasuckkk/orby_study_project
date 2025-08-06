import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<String> chamarOpenAI(String prompt) async {
  final apiKey = dotenv.env['OPENAI_API_KEY'];

  if (apiKey == null || apiKey.isEmpty) {
    throw Exception("API Key da OpenAI não encontrada.");
  }

  final response = await http.post(
    Uri.parse('https://api.openai.com/v1/chat/completions'),
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      "model": "gpt-3.5-turbo",
      "messages": [
        {"role": "user", "content": prompt}
      ],
      "temperature": 0.4
    }),
  );

  final content = jsonDecode(response.body)["choices"][0]["message"]["content"];
  return content.replaceAll(RegExp(r'```json|```'), '').trim();
}
