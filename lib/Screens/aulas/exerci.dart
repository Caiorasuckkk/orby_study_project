import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:orbyt/Screens/Menu/StudyPlan.dart';

class ExerciciosScreen extends StatefulWidget {
  final String materia;
  final String submateria;

  const ExerciciosScreen({
    super.key,
    required this.materia,
    required this.submateria,
  });

  @override
  State<ExerciciosScreen> createState() => _ExerciciosScreenState();
}

class _ExerciciosScreenState extends State<ExerciciosScreen> {
  List<dynamic> exercicios = [];
  List<int?> respostasSelecionadas = [];
  bool isLoading = true;
  bool mostrarResultado = false;
  bool provaFinalizada = false;

  @override
  void initState() {
    super.initState();
    carregarExercicios();
  }

  Future<void> carregarExercicios() async {
    final doc =
        await FirebaseFirestore.instance
            .collection("Estudo")
            .doc(widget.materia)
            .collection(widget.materia)
            .doc(widget.submateria)
            .get();

    final data = doc.data();
    if (data != null && data.containsKey("exercicios")) {
      setState(() {
        exercicios = data["exercicios"];
        respostasSelecionadas = List.filled(exercicios.length, null);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void finalizarExercicios() async {
    int acertos = 0;
    int erros = 0;

    for (int i = 0; i < exercicios.length; i++) {
      final resposta = exercicios[i]["resposta"];
      final alternativas = exercicios[i]["alternativas"];
      final indexSelecionado = respostasSelecionadas[i];
      if (indexSelecionado != null &&
          alternativas[indexSelecionado] == resposta) {
        acertos++;
      } else {
        erros++;
      }
    }

    final bool aprovado = acertos >= 3;


    if (aprovado) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection("usuarios")
            .doc(uid)
            .collection("Resultados")
            .doc(widget.submateria)
            .set({"status": "aprovado"});
      }
    }

    setState(() {
      mostrarResultado = true;
      provaFinalizada = true;
    });

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: const Color(0xFF1F2F3F),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            title: Row(
              children: [
                Icon(
                  aprovado ? Icons.emoji_events : Icons.warning_amber_rounded,
                  color: aprovado ? Colors.amber : Colors.redAccent,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    aprovado ? "Parabéns!" : "Tente novamente",
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "✅ Acertos: $acertos",
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "❌ Erros: $erros",
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text(
                  aprovado
                      ? "Você foi aprovado neste conteúdo! Continue assim. 👏"
                      : "Você precisa praticar mais para passar neste conteúdo.",
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.only(bottom: 12, right: 12),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Ver respostas",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              if (aprovado)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.shade700,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // fecha diálogo
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => StudyPlanScreen()),
                    ); // volta uma tela
                  },
                  child: const Text(
                    "Finalizar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              if (!aprovado)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrangeAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    setState(() => isLoading = true);

                    try {
                      await refazerQuestoes();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Erro ao gerar novas questões: $e"),
                        ),
                      );
                    }

                    setState(() {
                      isLoading = false;
                      mostrarResultado = false;
                      provaFinalizada = false;
                    });
                  },
                  child: const Text(
                    "Refazer",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
    );
  }

  bool todasRespondidas() {
    return !respostasSelecionadas.contains(null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A2B),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : exercicios.isEmpty
              ? const Center(
                child: Text(
                  "Nenhum exercício encontrado",
                  style: TextStyle(color: Colors.white),
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/orby_semtxt.png',
                              height: 70,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Orbyt',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Isso é apenas um teste rápido para ver se absorveu a matéria. Se caso não acertar 70% das questões, terá que tentar novamente para avançar.",
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 24),
                        ...List.generate(
                          exercicios.length,
                          (index) =>
                              _buildExercicioCard(exercicios[index], index),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed:
                          todasRespondidas() ? finalizarExercicios : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            todasRespondidas()
                                ? Colors.greenAccent.shade700
                                : Colors.grey,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 24,
                        ),
                      ),
                      child: const Text(
                        "Finalizar",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildExercicioCard(Map<String, dynamic> exercicio, int index) {
    final alternativas = exercicio["alternativas"] as List<dynamic>;
    final respostaCorreta = exercicio["resposta"];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2F3F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurpleAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exercício ${index + 1}: ${exercicio["pergunta"]}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(alternativas.length, (altIndex) {
            final alternativa = alternativas[altIndex];
            final selecionada = respostasSelecionadas[index] == altIndex;
            final correta = alternativa == respostaCorreta;

            Color? corTexto;
            if (mostrarResultado) {
              if (selecionada && correta) {
                corTexto = Colors.greenAccent;
              } else if (selecionada && !correta) {
                corTexto = Colors.redAccent;
              } else if (!selecionada && correta) {
                corTexto = Colors.green;
              } else {
                corTexto = Colors.white;
              }
            } else {
              corTexto = Colors.white;
            }

            return RadioListTile<int>(
              activeColor: Colors.greenAccent,
              title: Text(alternativa, style: TextStyle(color: corTexto)),
              value: altIndex,
              groupValue: respostasSelecionadas[index],
              onChanged:
                  mostrarResultado
                      ? null
                      : (value) {
                        setState(() {
                          respostasSelecionadas[index] = value;
                        });
                      },
            );
          }),
          if (mostrarResultado)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                "Explicação: ${exercicio["explicacao"]}",
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> refazerQuestoes() async {
    final prompt = StringBuffer();
    prompt.writeln(
      "Você é um professor de ${widget.materia} especializado em vestibulares.",
    );
    prompt.writeln(
      "O aluno respondeu os seguintes exercícios de ${widget.submateria}:",
    );

    for (int i = 0; i < exercicios.length; i++) {
      final pergunta = exercicios[i]['pergunta'];
      final alternativas = (exercicios[i]['alternativas'] as List).join(", ");
      final resposta = exercicios[i]['resposta'];
      final indexSelecionado = respostasSelecionadas[i];
      final respostaDoAluno =
          indexSelecionado != null
              ? exercicios[i]['alternativas'][indexSelecionado]
              : "Não respondeu";

      prompt.writeln('''
Pergunta ${i + 1}: $pergunta
Alternativas: $alternativas
Resposta correta: $resposta
Resposta do aluno: $respostaDoAluno
''');
    }

    prompt.writeln(
      "Crie 5 novos exercícios com base nas dificuldades do aluno, respeitando o mesmo estilo das perguntas originais. Retorne no seguinte formato JSON com aspas duplas externas e aspas simples internas:",
    );
    prompt.writeln('''[
  {
    "pergunta": "Texto da pergunta...",
    "alternativas": ["A", "B", "C", "D"],
    "resposta": "Letra correta",
    "explicacao": "Breve explicação da resposta correta"
  }
]''');

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['OPENAI_API_KEY']}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {"role": "user", "content": prompt.toString()},
          ],
          "temperature": 0.3,
        }),
      );

      final decoded = jsonDecode(response.body);
      final content = decoded["choices"]?[0]?["message"]?["content"];
      if (content == null) throw Exception("Resposta inválida da API");

      final cleaned = content.replaceAll(RegExp(r'```json|```'), '').trim();

      try {
        final List<dynamic> novosExercicios = jsonDecode(cleaned);
        setState(() {
          exercicios = novosExercicios;
          respostasSelecionadas = List.filled(novosExercicios.length, null);
          mostrarResultado = false;
        });
      } catch (e) {
        print(
          "Erro ao interpretar JSON direto. Tentando corrigir aspas internas...",
        );

        // Corrige aspas internas comuns
        final cleanedFixed = cleaned
            .replaceAll(r'\"', '"')
            .replaceAllMapped(RegExp(r"'([^']*?)'"), (m) => '"${m[1]}"');

        try {
          final List<dynamic> novosExercicios = jsonDecode(cleanedFixed);
          setState(() {
            exercicios = novosExercicios;
            respostasSelecionadas = List.filled(novosExercicios.length, null);
            mostrarResultado = false;
          });
        } catch (e) {
          print(" Erro ao corrigir JSON: $e");
          throw Exception("Erro ao interpretar exercícios da IA");
        }
      }
    } catch (e) {
      print("Erro ao gerar novos exercícios: $e");
      rethrow;
    }
  }
}
