import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'Orby/OrbyIntroScreen.dart';

class AlimentacaoScreen extends StatefulWidget {
  const AlimentacaoScreen({super.key});

  @override
  State<AlimentacaoScreen> createState() => _AlimentacaoScreenState();
}

class _AlimentacaoScreenState extends State<AlimentacaoScreen> {
  int _currentStep = 0;
  final Map<String, dynamic> respostas = {};
  final Map<String, TextEditingController> controllers = {
    "outro_objetivo": TextEditingController(),
    "restricao": TextEditingController(),
    "altura": TextEditingController(),
    "peso": TextEditingController(),
  };

  final objetivos = [
    'Emagrecer',
    'Ganhar massa muscular',
    'Melhorar a saúde',
    'Reeducação alimentar',
    'Outro'
  ];

  final opcoesRestricao = ['Nenhuma', 'Glúten', 'Lactose', 'Vegetariano', 'Vegano', 'Outro'];
  final preparo = ['Como fora', 'Preparo em casa', 'Ambos'];
  final refeicoes = ['2', '3', '4', '5 ou mais'];
  final suplementos = ['Sim', 'Não'];

  Future<void> _nextStep() async {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      await _salvarRespostas();
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OrbyIntroScreen()),
        );
      }
    }
  }

  Future<void> _salvarRespostas() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection("usuarios")
        .doc(uid)
        .collection("Objetivo")
        .doc("Alimentação")
        .set({
      "Tipo": "Alimentação",
      "Perguntas": respostas,
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Respostas salvas com sucesso!")),
      );
    }
  }

  Widget _buildCustomQuestion() {
    switch (_currentStep) {
      case 0:
        return _buildWithOther(objetivos, 'Qual o seu principal objetivo relacionado à alimentação?', 'objetivo', 'outro_objetivo');
      case 1:
        return _buildWithOther(opcoesRestricao, 'Você tem alguma restrição alimentar?', 'restricao', 'restricao');
      case 2:
        return _buildOptions(preparo, 'Você costuma comer fora ou preparar suas refeições?', 'preparo');
      case 3:
        return _buildOptions(refeicoes, 'Quantas refeições você costuma fazer por dia?', 'refeicoes');
      case 4:
        return _buildAlturaPesoSuplementos();
      default:
        return const SizedBox();
    }
  }

  Widget _buildWithOther(List<String> options, String pergunta, String key, String controllerKey) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(pergunta, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...options.map((opt) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() => respostas[key] = opt == 'Outro' ? controllers[controllerKey]!.text : opt);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: respostas[key] == opt ? Colors.blue : Colors.transparent,
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(opt, style: const TextStyle(color: Colors.white)),
            ),
          );
        }),
        if (respostas[key] == controllers[controllerKey]!.text || respostas[key] == 'Outro')
          TextField(
            controller: controllers[controllerKey],
            onChanged: (val) => setState(() => respostas[key] = val),
            decoration: _inputDecoration('Digite aqui'),
            style: const TextStyle(color: Colors.white),
          ),
      ],
    );
  }

  Widget _buildOptions(List<String> options, String pergunta, String key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(pergunta, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...options.map((opt) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => respostas[key] = opt),
              style: ElevatedButton.styleFrom(
                backgroundColor: respostas[key] == opt ? Colors.blue : Colors.transparent,
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(opt, style: const TextStyle(color: Colors.white)),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAlturaPesoSuplementos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Qual sua altura (em cm)?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controllers['altura'],
          keyboardType: TextInputType.number,
          onChanged: (val) => respostas['altura'] = val,
          decoration: _inputDecoration('Ex: 180'),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 16),
        const Text('Qual seu peso (em kg)?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controllers['peso'],
          keyboardType: TextInputType.number,
          onChanged: (val) => respostas['peso'] = val,
          decoration: _inputDecoration('Ex: 75'),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 16),
        _buildOptions(suplementos, 'Você faz uso de suplementos (proteína, vitaminas, etc.)?', 'suplementos'),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      filled: true,
      fillColor: Colors.white12,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(40)),
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
            Expanded(child: _buildCustomQuestion()),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextStep,
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
