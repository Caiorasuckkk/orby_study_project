import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../Services/openai_services.dart';
import 'SImuladoFinal.dart';

class SimuladoIntroScreen extends StatefulWidget {
  const SimuladoIntroScreen({super.key});

  @override
  State<SimuladoIntroScreen> createState() => _SimuladoIntroScreenState();
}

class _SimuladoIntroScreenState extends State<SimuladoIntroScreen> {
  String? tipoSelecionado;

  List<dynamic>? tryParseJsonList(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) return decoded;
    } catch (_) {
      final match = RegExp(r'\[.*\]', dotAll: true).firstMatch(content);
      if (match != null) {
        try {
          final cleaned = match.group(0);
          final safe = cleaned
              ?.replaceAll("“", '"')
              .replaceAll("”", '"')
              .replaceAll("‘", "'")
              .replaceAll("’", "'")
              .replaceAll('\n', ' ')
              .replaceAll('\r', '');
          final finalDecoded = jsonDecode(safe!);
          if (finalDecoded is List) return finalDecoded;
        } catch (_) {}
      }
    }
    return null;
  }

  Future<void> iniciarSimulado() async {
    if (tipoSelecionado == null) return;

    final distribuicao = tipoSelecionado == 'ENEM'
        ? {
      'Matemática': 45,
      'Química': 15,
      'Física': 15,
      'Biologia': 15,
      'História': 15,
      'Geografia': 15,
      'Filosofia': 7,
      'Sociologia': 8,
      'Português': 20,
      'Literatura': 5,
      'Artes': 5,
      'Educação Física': 5,
      'Tecnologias da Informação': 5,
      'Inglês': 5,
      'Espanhol': 5,
    }
        : {
      'Português': 10,
      'Matemática': 10,
      'História': 10,
      'Geografia': 10,
      'Biologia': 10,
      'Física': 10,
      'Química': 10,
      'Inglês': 10,
      'Interdisciplinares': 10,
    };

    List<Map<String, dynamic>> todasQuestoes = [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    for (final entry in distribuicao.entries) {
      final materia = entry.key;
      final quantidade = entry.value;
      int blocos = (quantidade / 10).ceil();

      for (int i = 0; i < blocos; i++) {
        final prompt = '''
Gere até 10 questões objetivas com alternativas completas e explicações claras sobre o tema "$materia", no estilo da prova $tipoSelecionado.
Formato obrigatório em JSON:

[
  {
    "pergunta": "Texto da pergunta com enunciado completo.",
    "alternativas": ["Alternativa A completa", "Alternativa B completa", "Alternativa C completa", "Alternativa D completa", "Alternativa E completa"],
    "resposta": "C",
    "explicacao": "Explicação clara da resposta correta."
  }
]
''';

        try {
          final content = await chamarOpenAI(prompt);
          final blocQuestoes = tryParseJsonList(content);

          if (blocQuestoes == null) {
            throw 'JSON malformado ou sem questões válidas.';
          }

          for (var questao in blocQuestoes) {
            final pergunta = questao['pergunta'];
            final alternativas = questao['alternativas'];
            final resposta = questao['resposta'];
            final explicacao = questao['explicacao'];

            if (pergunta is String &&
                explicacao is String &&
                alternativas is List &&
                alternativas.length >= 2 &&
                resposta is String &&
                resposta.length == 1) {
              final respostaIndex = resposta.toUpperCase().codeUnitAt(0) - 65;
              if (respostaIndex >= 0 && respostaIndex < alternativas.length) {
                todasQuestoes.add({
                  'pergunta': pergunta,
                  'alternativas': alternativas.map((e) => e.toString()).toList(),
                  'resposta': respostaIndex,
                  'explicacao': explicacao,
                });
              }
            }
          }
        } catch (e, stack) {
          debugPrint('Erro em $materia: $e\n$stack');
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao gerar questões de $materia. Pulando...')),
          );
          continue;
        }
      }
    }

    Navigator.of(context).pop();

    if (todasQuestoes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma questão válida foi gerada.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SimuladoQuestoesScreen(
          exercicios: todasQuestoes,
          area: tipoSelecionado!,
        ),
      ),
    );
  }

  Widget buildTipoButton(String tipo, Color cor) {
    final bool isSelected = tipoSelecionado == tipo;

    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            tipoSelecionado = tipo;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? cor : Colors.white12,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: cor, width: 1),
        ),
        child: Text(
          tipo,
          style: TextStyle(
            color: isSelected ? Colors.white : cor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A2B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Simulado', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            const Text(
              'Vamos testar seus conhecimentos!',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              'Escolha o tipo de simulado:',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                buildTipoButton('ENEM', Colors.orange),
                const SizedBox(width: 16),
                buildTipoButton('FUVEST', Colors.blue),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: tipoSelecionado == null ? null : iniciarSimulado,
                icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                label: const Text(
                  'Iniciar Simulado',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  disabledBackgroundColor: Colors.grey.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
