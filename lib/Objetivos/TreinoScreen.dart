import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'Orby/OrbyIntroScreen.dart';

class MontarTreinoScreen extends StatefulWidget {
  const MontarTreinoScreen({super.key});

  @override
  State<MontarTreinoScreen> createState() => _MontarTreinoScreenState();
}

class _MontarTreinoScreenState extends State<MontarTreinoScreen> {
  int _currentStep = 0;
  final Map<String, dynamic> respostas = {};
  final Map<String, TextEditingController> controllers = {
    "equipamentoOutro": TextEditingController(),
    "lesaoDescricao": TextEditingController(),
    "atividadeOutro": TextEditingController(),
    "objetivoOutro": TextEditingController(),
  };

  final niveis = ['Iniciante', 'Intermediário', 'Avançado'];
  final equipamentos = ['Academia completa', 'Pesos livres', 'Faixas elásticas', 'Nenhum', 'Outros'];
  final diasTreino = ['2x', '3x', '4x', '5x ou mais'];
  final simNao = ['Sim', 'Não'];
  final objetivos = ['Ganho de massa', 'Perda de gordura', 'Resistência', 'Saúde geral', 'Outro'];

  void _nextStep() {
    setState(() => _currentStep++);
  }

  Future<void> _salvarRespostas() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection("usuarios")
        .doc(uid)
        .collection("Objetivo")
        .doc("Treino")
        .set({
      "Tipo": "Treino",
      "Perguntas": respostas,
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Respostas salvas com sucesso!")),
      );
    }
  }

  Widget _buildPergunta() {
    switch (_currentStep) {
      case 0:
        return _buildOptions('Qual é o seu nível de experiência com treinos?', niveis, 'nivel');
      case 1:
        return _buildOptionsComTexto('Você tem acesso a quais equipamentos?', equipamentos, 'equipamentos', controllers['equipamentoOutro']!);
      case 2:
        return _buildOptions('Quantos dias por semana você pretende treinar?', diasTreino, 'frequencia');
      case 3:
        return _buildSimNaoComCampo('Você tem alguma lesão ou limitação física?', 'lesao', controllers['lesaoDescricao']!);
      case 4:
        return _buildSimNaoComCampo('Faz mais alguma atividade física?', 'atividade', controllers['atividadeOutro']!);
      case 5:
        return _buildOptionsComTexto('Quais são seus objetivos principais?', objetivos, 'objetivo', controllers['objetivoOutro']!);
      default:
        return const SizedBox();
    }
  }

  Widget _buildOptions(String pergunta, List<String> opcoes, String chave) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(pergunta, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...opcoes.map((opcao) => Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: respostas[chave] == opcao ? const Color(0xFF4A90E2) : Colors.transparent,
              side: const BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => setState(() => respostas[chave] = opcao),
            child: Text(opcao, style: const TextStyle(color: Colors.white)),
          ),
        ))
      ],
    );
  }

  Widget _buildOptionsComTexto(String pergunta, List<String> opcoes, String chave, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(pergunta, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...opcoes.map((opcao) => Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: respostas[chave] == opcao ? const Color(0xFF4A90E2) : Colors.transparent,
              side: const BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => setState(() => respostas[chave] = opcao == 'Outros' ? controller.text : opcao),
            child: Text(opcao, style: const TextStyle(color: Colors.white)),
          ),
        )),
        if (respostas[chave] == controller.text || respostas[chave] == 'Outros')
          TextField(
            controller: controller,
            onChanged: (val) => setState(() => respostas[chave] = val),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Digite aqui',
              labelStyle: TextStyle(color: Colors.white),
              filled: true,
              fillColor: Colors.white12,
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(40))),
            ),
          )
      ],
    );
  }

  Widget _buildSimNaoComCampo(String pergunta, String chave, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Removido o Text(pergunta) aqui porque já é exibido por _buildOptions abaixo
        _buildOptions(pergunta, simNao, chave),
        if (respostas[chave] == 'Sim')
          TextField(
            controller: controller,
            onChanged: (val) => respostas['${chave}_descricao'] = val,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Descreva',
              labelStyle: TextStyle(color: Colors.white),
              filled: true,
              fillColor: Colors.white12,
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(40))),
            ),
          )
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A2B),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                Image.asset('assets/images/orby_semtxt.png', height: 70),
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
            const SizedBox(height: 60),
            Expanded(child: _buildPergunta()),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _currentStep < 5
                    ? _nextStep
                    : () async {
                  await _salvarRespostas();
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OrbyIntroScreen()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                ),
                child: Text(
                  _currentStep == 4 ? "Finalizar" : "Próximo",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
