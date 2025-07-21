import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'Orby/OrbyIntroScreen.dart';

class HabitosScreen extends StatefulWidget {
  const HabitosScreen({super.key});

  @override
  State<HabitosScreen> createState() => _HabitosScreenState();
}

class _HabitosScreenState extends State<HabitosScreen> {
  int _currentStep = 0;

  final TextEditingController horarioAcordarController = TextEditingController();
  final TextEditingController horarioDormirController = TextEditingController();
  String? tempoLivre;
  List<String> habitosRelacionados = [];
  String? notificacoes;
  String? rotina;
  final TextEditingController habitosTentadosController = TextEditingController();

  final List<String> tempoLivreOptions = [
    'Menos de 30 minutos',
    '30-60 minutos',
    '1-2 horas',
    'Mais de 2 horas'
  ];

  final List<String> habitosOptions = [
    'Saúde Física', 'Saúde Mental', 'Produtividade', 'Todos'
  ];

  final List<String> rotinaOptions = [
    'Fixas', 'Flexíveis', 'Nao me importo'
  ];

  void _nextStep() async {
    if (!_respostaValida()) return;

    if (_currentStep < 5) {
      setState(() => _currentStep++);
    } else {
      await _finalizarQuestionario();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OrbyIntroScreen()),
        );
      }
    }
  }


  bool _respostaValida() {
    switch (_currentStep) {
      case 0:
        return horarioAcordarController.text.isNotEmpty && horarioDormirController.text.isNotEmpty;
      case 1:
        return tempoLivre != null;
      case 2:
        return habitosRelacionados.isNotEmpty;
      case 3:
        return notificacoes != null;
      case 4:
        return rotina != null;
      case 5:
        return true; // opcional
      default:
        return true;
    }
  }

  Future<void> _finalizarQuestionario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final perguntas = {
      "Pergunta 1": {
        "Qual horário você costuma acordar e dormir?": {
          "Horário de Acordar": horarioAcordarController.text,
          "Horário de Dormir": horarioDormirController.text,
        }
      },
      "Pergunta 2": {
        "Quanto tempo livre você tem por dia para se dedicar a novos hábitos?": tempoLivre
      },
      "Pergunta 3": {
        "Você quer incluir hábitos relacionados a:": habitosRelacionados
      },
      "Pergunta 4": {
        "Você quer notificações diárias como lembretes?": notificacoes
      },
      "Pergunta 5": {
        "Prefere rotinas mais fixas ou flexíveis?": rotina
      },
      "Pergunta 6": {
        "Que hábitos você já tentou adotar no passado e não conseguiu manter?":
        habitosTentadosController.text.trim()
      }
    };

    final docRef = FirebaseFirestore.instance
        .collection("usuarios")
        .doc(uid)
        .collection("Objetivo")
        .doc("Bons Habitos");

    await docRef.set({
      "Perguntas": perguntas,
    });
  }

  String _getPerguntaTexto() {
    switch (_currentStep) {
      case 0:
        return "Qual horário você costuma acordar e dormir?";
      case 1:
        return "Quanto tempo livre você tem por dia para se dedicar a novos hábitos?";
      case 2:
        return "Você quer incluir hábitos relacionados a:";
      case 3:
        return "Você quer notificações diárias como lembretes?";
      case 4:
        return "Prefere rotinas mais fixas ou flexíveis?";
      case 5:
        return "Que hábitos você já tentou adotar no passado e não conseguiu manter?";
      default:
        return "";
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          children: [
            _buildTimePickerField(horarioAcordarController, "Horário de Acordar"),
            const SizedBox(height: 16),
            _buildTimePickerField(horarioDormirController, "Horário de Dormir"),
          ],
        );
      case 1:
        return DropdownButtonFormField<String>(
          value: tempoLivre,
          onChanged: (value) => setState(() => tempoLivre = value),
          items: tempoLivreOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
          decoration: _inputDecoration("Tempo Livre por Dia"),
          dropdownColor: const Color(0xFF0D1A2B),
          style: const TextStyle(color: Colors.white),
        );
      case 2:
        return Wrap(
          spacing: 8,
          children: habitosOptions.map((opt) => ChoiceChip(
            label: Text(opt),
            selected: habitosRelacionados.contains(opt),
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  habitosRelacionados.add(opt);
                } else {
                  habitosRelacionados.remove(opt);
                }
              });
            },
          )).toList(),
        );
      case 3:
        return Column(
          children: ['Sim', 'Nao'].map((opt) => Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: notificacoes == opt ? const Color(0xFF4A90E2) : Colors.transparent,
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => setState(() => notificacoes = opt),
              child: Text(opt, style: const TextStyle(color: Colors.white)),
            ),
          )).toList(),
        );
      case 4:
        return Column(
          children: rotinaOptions.map((opt) => Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: rotina == opt ? const Color(0xFF4A90E2) : Colors.transparent,
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => setState(() => rotina = opt),
              child: Text(opt, style: const TextStyle(color: Colors.white)),
            ),
          )).toList(),
        );
      case 5:
        return TextField(
          controller: habitosTentadosController,
          maxLines: 5,
          decoration: _inputDecoration("Digite aqui... (opcional)"),
          style: const TextStyle(color: Colors.white),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildTimePickerField(TextEditingController controller, String label) {
    return GestureDetector(
      onTap: () async {
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );

        if (pickedTime != null) {
          setState(() {
            controller.text = pickedTime.format(context);
          });
        }
      },
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration(label),
        ),
      ),
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
            Text(
              _getPerguntaTexto(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(child: _buildStepContent()),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _respostaValida() ? _nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                ),
                child: Text(
                  _currentStep == 5 ? "Finalizar" : "Próximo",
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      filled: true,
      fillColor: Colors.white12,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(40)),
    );
  }
}
