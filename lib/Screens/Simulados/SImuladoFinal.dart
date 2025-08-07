import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';



class SimuladoQuestoesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> exercicios;
  final String area;

  const SimuladoQuestoesScreen({
    super.key,
    required this.exercicios,
    required this.area,
  });

  @override
  State<SimuladoQuestoesScreen> createState() => _SimuladoQuestoesScreenState();
}

class _SimuladoQuestoesScreenState extends State<SimuladoQuestoesScreen> {
  late List<int?> respostasSelecionadas;
  bool finalizado = false;

  @override
  void initState() {
    super.initState();
    respostasSelecionadas = List.filled(widget.exercicios.length, null);
  }

  int normalizarResposta(dynamic resposta) {
    if (resposta is int) return resposta;
    if (resposta is String && resposta.length == 1) {
      return resposta.toUpperCase().codeUnitAt(0) - 65;
    }
    return -1;
  }

  Future<void> finalizarSimulado() async {
    int acertos = 0;

    for (int i = 0; i < widget.exercicios.length; i++) {
      final correta = normalizarResposta(widget.exercicios[i]['resposta']);
      if (respostasSelecionadas[i] == correta) {
        acertos++;
      }
    }

    final erros = widget.exercicios.length - acertos;
    final aproveitamento = ((acertos / widget.exercicios.length) * 100).toStringAsFixed(1);


    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final agora = DateTime.now();
      final dataFormatada =
          '${agora.day.toString().padLeft(2, '0')}/${agora.month.toString().padLeft(2, '0')}/${agora.year}';

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('Objetivo')
          .doc('Estudos')
          .collection('Simulados')
          .add({
        'area': widget.area,
        'acertos': acertos,
        'erros': erros,
        'aproveitamento': double.parse(aproveitamento),
        'data': dataFormatada,
      });
    }

    setState(() {
      finalizado = true;
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1F2F3F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Simulado Finalizado', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✅ Acertos: $acertos', style: const TextStyle(color: Colors.green)),
            Text('❌ Erros: $erros', style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 8),
            Text('🎯 Aproveitamento: $aproveitamento%', style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Voltar ao Plano de Estudos', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, '/studyplan');
            },
          )
        ],
      ),
    );
  }

  Color? corAlternativa(int indexQuestao, int indexAlternativa) {
    final correta = normalizarResposta(widget.exercicios[indexQuestao]['resposta']);
    final selecionada = respostasSelecionadas[indexQuestao];

    if (!finalizado) {
      return selecionada == indexAlternativa ? Colors.deepPurple : null;
    }

    if (indexAlternativa == correta) {
      return Colors.green;
    } else if (indexAlternativa == selecionada) {
      return Colors.red;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A2B),
      appBar: AppBar(
        title: Text('Simulado ${widget.area}', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.exercicios.length + (finalizado ? 0 : 1),
        itemBuilder: (context, index) {
          if (!finalizado && index == widget.exercicios.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: ElevatedButton.icon(
                onPressed: finalizarSimulado,
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text(
                  'Finalizar Simulado',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            );
          }

          final questao = widget.exercicios[index];
          final alternativas = (questao['alternativas'] as List).map((e) => e.toString()).toList();

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2F3F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Questão ${index + 1}',
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  questao['pergunta'].toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < alternativas.length; i++)
                  GestureDetector(
                    onTap: !finalizado
                        ? () {
                      setState(() {
                        respostasSelecionadas[index] = i;
                      });
                    }
                        : null,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: corAlternativa(index, i),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: respostasSelecionadas[index] == i
                              ? Colors.white
                              : Colors.white24,
                        ),
                      ),
                      child: Text(
                        alternativas[i],
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ),
                if (finalizado)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Explicação: ${questao['explicacao']}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
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
