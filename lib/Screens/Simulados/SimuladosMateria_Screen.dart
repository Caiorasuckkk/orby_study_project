import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../Services/openai_services.dart';
import 'SimuladoQuestoesScreen.dart';
import 'dart:convert';

class SimuladoScreen extends StatefulWidget {
  final String area;

  const SimuladoScreen({super.key, required this.area});

  @override
  State<SimuladoScreen> createState() => _SimuladoScreenState();
}

class _SimuladoScreenState extends State<SimuladoScreen> {
  Map<String, dynamic> resultados = {};
  Map<String, List<String>> topicosAprovadosPorMateria = {};

  final Map<String, String> areaPorMateria = {
    'Matematica': 'Exatas',
    'Física': 'Exatas',
    'Química': 'Exatas',
    'Biologia': 'Biológicas',
    'História': 'Humanas',
    'Geografia': 'Humanas',
    'Filosofia': 'Humanas',
    'Sociologia': 'Humanas',
    'Gramática': 'Linguagens',
    'Literatura': 'Linguagens',
    'Redação': 'Linguagens',
    'Inglês': 'Linguagens',
    'Espanhol': 'Linguagens',
  };

  @override
  void initState() {
    super.initState();
    carregarTopicos();
  }

  Future<void> carregarTopicos() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final planoSnapshot = await FirebaseFirestore.instance
          .doc('usuarios/${user.uid}/Objetivo/Estudos')
          .get();
      resultados = planoSnapshot.data()?['Resultados'] ?? {};

      final materias = areaPorMateria.entries
          .where((entry) => entry.value == widget.area)
          .map((entry) => entry.key)
          .toList();

      final Map<String, List<String>> topicosMap = {};

      for (final materia in materias) {
        final subtopicosSnap = await FirebaseFirestore.instance
            .collection('Estudo')
            .doc(materia)
            .collection(materia)
            .get();
        final aprovados = subtopicosSnap.docs
            .map((doc) => doc.id)
            .where((id) => resultados[id] == 'aprovado')
            .toList();

        if (aprovados.isNotEmpty) {
          topicosMap[materia] = aprovados;
        }
      }

      setState(() {
        topicosAprovadosPorMateria = topicosMap;
      });
    } catch (e) {
      print('Erro ao carregar tópicos aprovados: $e');
    }
  }

  Future<void> gerarSimulado() async {
    Future<List<dynamic>> gerar15Questoes(String materia, List<String> topicos) async {
      final prompt = StringBuffer();
      prompt.writeln("Você é um professor especialista em $materia.");
      prompt.writeln("Crie exatamente 15 exercícios de múltipla escolha (com 4 alternativas cada), cobrindo os tópicos abaixo.");
      prompt.writeln("Cada exercício deve conter:");
      prompt.writeln("- 'pergunta': enunciado da questão");
      prompt.writeln("- 'alternativas': lista com 4 opções (A, B, C, D)");
      prompt.writeln("- 'resposta': alternativa correta (A, B, C ou D)");
      prompt.writeln("- 'explicacao': justificativa da resposta");
      prompt.writeln("IMPORTANTE: evite aspas duplas dentro da pergunta. Se usar, escape com \\\".");
      prompt.writeln("Retorne APENAS uma lista JSON com 15 objetos, nada antes nem depois.");
      prompt.writeln("\nTópicos:\n${topicos.map((t) => '- $t').join('\n')}");

      final content = await chamarOpenAI(prompt.toString());
      final cleaned = content.replaceAll(RegExp(r'```json|```'), '').trim();

      List<dynamic> listaFinal;

      try {
        final parsed = jsonDecode(cleaned);
        if (parsed is List) {
          listaFinal = parsed;
        } else {
          throw Exception("❌ Esperado uma lista JSON, mas veio um objeto.");
        }
      } catch (_) {
        try {
          final corrigido = corrigirAspasDuplas(cleaned);
          final parsed = jsonDecode(corrigido);
          if (parsed is List) {
            listaFinal = parsed;
          } else {
            throw Exception("❌ Mesmo após correção, JSON não é uma lista.");
          }
        } catch (_) {
          throw Exception("❌ Erro ao decodificar JSON mesmo após correção.");
        }
      }

      if (listaFinal.length != 15) {
        throw Exception("❌ Foram geradas ${listaFinal.length} questões, e não 15.");
      }

      for (var questao in listaFinal) {
        questao['materia'] = materia;
      }

      return listaFinal;
    }

    try {
      final List<dynamic> todos = [];

      for (final entry in topicosAprovadosPorMateria.entries) {
        final materia = entry.key;
        final topicos = entry.value;

        final exercicios1 = await gerar15Questoes(materia, topicos);
        final exercicios2 = await gerar15Questoes(materia, topicos);
        todos.addAll(exercicios1);
        todos.addAll(exercicios2);
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SimuladoQuestoesScreen_Materias(
            exercicios: todos,
            area: widget.area,
          ),
        ),
      );
    } catch (e) {
      print("❌ Erro ao gerar simulado: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao gerar simulado')),
      );
    }
  }

  String corrigirAspasDuplas(String texto) {
    final aspasCorrigidas = texto.replaceAllMapped(
      RegExp(r'"(.*?)"'),
          (match) {
        String conteudo = match[1]!;
        conteudo = conteudo.replaceAll('"', r'\"');
        return '"$conteudo"';
      },
    );

    final duplasCorrigidas = aspasCorrigidas.replaceAllMapped(
      RegExp(r"'([^']*?)'"),
          (m) => '"${m[1]}"',
    );

    return duplasCorrigidas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A2B),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Image.asset('assets/images/orby_semtxt.png', height: 40),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Orbyt',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Simulado de ${widget.area}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.amberAccent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade800,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Text(
                        'Este simulado é apenas um teste para avaliar seu progresso no estudo.\n\nVocê pode realizá-lo quantas vezes quiser e não haverá limite de tempo.',
                        style: TextStyle(fontSize: 15, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'O simulado será composto das seguintes matérias que você concluiu até agora:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              topicosAprovadosPorMateria.isEmpty
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Text(
                    'Nenhum tópico aprovado ainda.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              )
                  : Column(
                children: topicosAprovadosPorMateria.entries.map((entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade900,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.lightBlueAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...entry.value.map(
                              (topico) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '• $topico',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton.icon(
                  onPressed: topicosAprovadosPorMateria.isEmpty ? null : gerarSimulado,
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text(
                    'Realizar Simulado',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    topicosAprovadosPorMateria.isEmpty ? Colors.grey : Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
