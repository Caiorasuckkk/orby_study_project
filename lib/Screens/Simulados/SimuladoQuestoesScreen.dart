import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SimuladoQuestoesScreen_Materias extends StatefulWidget {
  final List<dynamic> exercicios;
  final String area; // Ex: 'Exatas', 'Humanas'...

  const SimuladoQuestoesScreen_Materias({super.key, required this.exercicios, required this.area});

  @override
  State<SimuladoQuestoesScreen_Materias> createState() => _SimuladoQuestoesScreen_MateriasState();
}

class _SimuladoQuestoesScreen_MateriasState extends State<SimuladoQuestoesScreen_Materias> {
  List<int?> respostasSelecionadas = [];
  bool finalizado = false;
  int acertos = 0;
  int erros = 0;
  double aproveitamento = 0.0;

  @override
  void initState() {
    super.initState();
    respostasSelecionadas = List<int?>.filled(widget.exercicios.length, null);
  }

  void finalizarSimulado() async {
    int totalAcertos = 0;

    for (int i = 0; i < widget.exercicios.length; i++) {
      final correta = widget.exercicios[i]['resposta'];
      final indexSelecionado = respostasSelecionadas[i];
      final respostaAluno = indexSelecionado != null ? widget.exercicios[i]['alternativas'][indexSelecionado] : null;
      if (respostaAluno == correta) {
        totalAcertos++;
      }
    }

    final int totalQuestoes = widget.exercicios.length;
    final double percentual = (totalAcertos / totalQuestoes) * 100;

    setState(() {
      finalizado = true;
      acertos = totalAcertos;
      erros = totalQuestoes - totalAcertos;
      aproveitamento = percentual;
    });

    await salvarSimulado();
  }

  Future<void> salvarSimulado() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final data = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    final materiasUsadas = widget.exercicios.map((e) => e['materia'] ?? '').toSet().toList();

    final simuladoData = {
      'aproveitamento': aproveitamento.toStringAsFixed(1) + '%',
      'area': widget.area,
      'data': data,
      'materias': materiasUsadas,
    };

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('Objetivo')
        .doc('Estudos')
        .collection('Simulados')
        .add(simuladoData);

  }

  Widget buildAlternativas(int index, List<dynamic> alternativas, String respostaCorreta) {
    return Column(
      children: List.generate(alternativas.length, (altIndex) {
        final selecionado = respostasSelecionadas[index] == altIndex;
        final cor = finalizado
            ? (alternativas[altIndex] == respostaCorreta
            ? Colors.green
            : selecionado
            ? Colors.red
            : Colors.grey.shade800)
            : (selecionado ? Colors.blueAccent : Colors.grey.shade800);

        return GestureDetector(
          onTap: finalizado
              ? null
              : () {
            setState(() {
              respostasSelecionadas[index] = altIndex;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    alternativas[altIndex],
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A2B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Simulado', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (!finalizado) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Deseja sair do Simulado?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Não'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Fecha o AlertDialog
                        Navigator.pop(context); // Sai da tela do simulado
                      },

                      child: const Text('Sim'),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.exercicios.length + 1,
        itemBuilder: (context, index) {
          if (index == widget.exercicios.length) {
            return Column(
              children: [
                if (finalizado) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Acertos: $acertos   |   Erros: $erros',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Aproveitamento: ${aproveitamento.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    if (finalizado) {
                      Navigator.pop(context);
                    } else {
                      finalizarSimulado();
                    }
                  },
                  icon: Icon(finalizado ? Icons.exit_to_app : Icons.check, color: Colors.white),
                  label: Text(
                    finalizado ? 'Sair' : 'Finalizar Simulado',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: finalizado ? Colors.redAccent : Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          }

          final exercicio = widget.exercicios[index];
          final pergunta = exercicio['pergunta'];
          final alternativas = exercicio['alternativas'];
          final resposta = exercicio['resposta'];
          final explicacao = exercicio['explicacao'];

          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade900,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Questão ${index + 1}',
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  pergunta,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 12),
                buildAlternativas(index, alternativas, resposta),
                if (finalizado)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Explicação: $explicacao',
                      style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
