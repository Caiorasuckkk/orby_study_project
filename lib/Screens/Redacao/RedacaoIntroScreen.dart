import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'RedacaoFazer.dart';



class RedacaoIntroScreen extends StatefulWidget {
  const RedacaoIntroScreen({super.key});

  @override
  State<RedacaoIntroScreen> createState() => _RedacaoIntroScreenState();
}

class _RedacaoIntroScreenState extends State<RedacaoIntroScreen> {
  Future<Map<String, dynamic>> gerarTemaRedacao() async {
    final prompt = StringBuffer();
    prompt.writeln("Você é um gerador de temas de redação estilo ENEM.");
    prompt.writeln("Crie um tema atual e 3 textos de referência curtos e diferentes (um pode ser estatístico, outro de opinião, outro histórico, por exemplo).");
    prompt.writeln("Retorne um JSON com os campos:");
    prompt.writeln("- 'tema': (string) com o título do tema de redação");
    prompt.writeln("- 'textos': (lista de 3 strings) com os textos de apoio");
    prompt.writeln("Exemplo de estrutura:");
    prompt.writeln("{ \"tema\": \"O impacto das redes sociais na saúde mental dos jovens\", \"textos\": [\"Texto 1...\", \"Texto 2...\", \"Texto 3...\"] }");
    prompt.writeln("Importante: não adicione comentários ou explicações fora do JSON.");

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${dotenv.env['OPENAI_API_KEY']}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [{"role": "user", "content": prompt.toString()}],
        "temperature": 0.7,
      }),
    );

    final decoded = jsonDecode(response.body);
    final content = decoded["choices"]?[0]?["message"]?["content"];
    if (content == null) throw Exception("Resposta vazia da API.");

    final cleaned = content.replaceAll(RegExp(r'```json|```'), '').trim();

    try {
      final parsed = jsonDecode(cleaned);
      if (parsed is Map<String, dynamic>) return parsed;
      throw Exception("Resposta da API não é um JSON válido.");
    } catch (e) {
      throw Exception("Erro ao decodificar JSON: $e");
    }
  }

  Future<void> iniciarRedacao() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final tema = await gerarTemaRedacao();
      if (!mounted) return;
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RedacaoEscreverScreen(
            tema: tema['tema'],
            textosDeReferencia: List<String>.from(tema['textos']),
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar tema: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A2B),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Row(
                children: [
                  Image.asset('assets/images/orby_semtxt.png', height: 40),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Orbyt',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Introdução à Redação',
                style: TextStyle(color: Colors.amberAccent, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nesta etapa, você irá praticar a redação dissertativo-argumentativa. '
                    'Você receberá um tema atual e textos de apoio para embasar seu texto.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),
              const Text(
                'Regras da Redação (ENEM / Vestibulares):',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                '• Tema dissertativo-argumentativo.\n'
                    '• Mínimo: 7 linhas ou 200 palavras.\n'
                    '• Máximo: 30 linhas ou cerca de 600 palavras.\n'
                    '• Texto deve propor solução e respeitar os direitos humanos.\n'
                    '• Fugir do tema ou copiar os textos zera a nota.',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: iniciarRedacao,
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                label: const Text(
                  'Começar Redação',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
