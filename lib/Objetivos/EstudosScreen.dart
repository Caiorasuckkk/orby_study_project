import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Screens/Menu/StudyPlan.dart';
import '../Services/openai_services.dart';
import 'Orby/OrbyIntroScreen.dart';

class EstudosScreen extends StatefulWidget {
  const EstudosScreen({super.key});

  @override
  State<EstudosScreen> createState() => _EstudosScreenState();
}

class _EstudosScreenState extends State<EstudosScreen> {
  int _currentStep = 0;
  String? objetivoEstudo;
  final Map<String, dynamic> respostas = {};
  String? modoEscolhido; // "padrao" ou "personalizado"

  final Map<String, TextEditingController> controllers = {
    "outro": TextEditingController(),
    "motivacao": TextEditingController(),
    "dataProva": TextEditingController(),
  };
  DateTime? dataProva;
  List<String> materiasSelecionadas = [];

  final objetivos = ['Vestibular/Enem'];

  final estilosAprendizado = [
    'Visual',
    'Auditivo',
    'Cinestésico',
    'Leitura/Escrita',
  ];
  final turnos = ['Manhã', 'Tarde', 'Noite'];
  final diasSemana = [
    '1 dia',
    '2 dias',
    '3 dias',
    '4 dias',
    '5 dias',
    '6 dias',
    'Todos os dias',
  ];
  final materias = [
    'Inglês',
    'Espanhol',
    'Filosofia',
    'Sociologia',
    'Matematica',
    'Biologia',
    'Química',
    'Física',
    'Geografia',
    'Historia',
    'Portugues',
    'Literatura',
  ];

  void _nextStep() => setState(() => _currentStep++);

  Future<Map<String, List<String>>> buscarConteudos() async {
    final db = FirebaseFirestore.instance;
    final Map<String, List<String>> conteudos = {};
    for (final materia in materias) {
      final snapshot = await db.collection('Estudo/$materia/$materia').get();
      final topicos = snapshot.docs.map((doc) => doc.id).toList();
      conteudos[materia] = topicos;
      print("📚 $materia: ${topicos.length} tópicos");
    }
    return conteudos;
  }

  Future<void> gerarPlanoEstudosPorBlocos(Map<String, List<String>> conteudos) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("Usuário não autenticado");

    final planoFinal = <String, Map<String, dynamic>>{};
    const maxTopicosPorBloco = 10;

    // Informações do usuário
    final diasSelecionado = respostas['dias']?.toString() ?? '5 dias';
    final diasPorSemana = int.tryParse(RegExp(r'\d+').stringMatch(diasSelecionado) ?? '5') ?? 5;
    final dataProvaStr = respostas['dataProva'] as String?;
    final dataProva = dataProvaStr != null ? DateTime.tryParse(dataProvaStr) : null;
    final hoje = DateTime.now();
    final semanasRestantes = dataProva != null ? (dataProva.difference(hoje).inDays / 7).ceil() : 4;

    for (final entry in conteudos.entries) {
      final materia = entry.key;
      final topicos = entry.value;

      for (var i = 0; i < topicos.length; i += maxTopicosPorBloco) {
        final bloco = topicos.skip(i).take(maxTopicosPorBloco).toList();

        final prompt = StringBuffer();
        prompt.writeln("Você é um organizador de planos de estudos personalizado.");
        prompt.writeln("Crie um plano de estudos para a matéria $materia.");
        prompt.writeln("Distribua os seguintes tópicos ao longo de $semanasRestantes semanas, com $diasPorSemana dias de estudo por semana.");
        if (dataProva != null) {
          prompt.writeln("O plano deve terminar no máximo até a data da prova: ${dataProva.day}/${dataProva.month}/${dataProva.year}.");
        }
        prompt.writeln("Formato de resposta JSON:");
        prompt.writeln('''{
  "Semana 1": {
    "Segunda-feira": ["Tópico 1", "Tópico 2"],
    ...
  }
}''');
        prompt.writeln("Tópicos:");
        bloco.forEach((t) => prompt.writeln("- $t"));

        final response = await chamarOpenAI(prompt.toString());
        final cleaned = response.replaceAll(RegExp(r'```json|```'), '').trim();

        Map<String, dynamic> jsonParcial;
        try {
          jsonParcial = jsonDecode(cleaned);
        } catch (e) {
          print("Erro ao decodificar resposta parcial: $e");
          continue;
        }

        jsonParcial.forEach((semana, dias) {
          planoFinal.putIfAbsent(semana, () => {});
          (dias as Map<String, dynamic>).forEach((dia, topicosDia) {
            planoFinal[semana]!.putIfAbsent(dia, () => []);
            (planoFinal[semana]![dia] as List).addAll(topicosDia);
          });
        });
      }
    }

    await FirebaseFirestore.instance
        .collection("usuarios")
        .doc(uid)
        .collection("Objetivo")
        .doc("Estudos")
        .set({
      "Tipo": "Estudos",
      "PlanoGerado": planoFinal,
    }, SetOptions(merge: true));
  }


  Future<void> _salvarRespostas() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    respostas['materiasDificeis'] = materiasSelecionadas;

    await FirebaseFirestore.instance
        .collection("usuarios")
        .doc(uid)
        .collection("Objetivo")
        .doc("Estudos")
        .set({"Tipo": "Estudos", "Perguntas": respostas});
    if (respostas['Objetivo'] == 'Vestibular/Enem') {
      final conteudos = await buscarConteudos();
     await gerarPlanoEstudosPorBlocos(conteudos);
      (conteudos);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Plano de estudos gerado e salvo com sucesso!"),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudyPlanScreen()),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Respostas salvas com sucesso!")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OrbyIntroScreen()),
        );
      }
    }
  }

  Widget _buildCustomQuestion() {
    if (modoEscolhido == null) {
      return _buildLabeledOptions(
        'Como deseja montar seu plano de estudos?',
        ['Plano Padrão (aulas já organizadas)', 'Plano Personalizado com IA'],
        null,
        (val) {
          setState(() {
            modoEscolhido = val.contains('Padrão') ? 'padrao' : 'personalizado';
          });
        },
      );
    }

    switch (_currentStep) {
      case 0:
        return _buildLabeledOptions(
          'Você estuda para qual tipo de objetivo?',
          objetivos,
          objetivoEstudo,
          (val) {
            setState(() {
              objetivoEstudo = val;
              respostas['Objetivo'] = val;
            });
          },
        );
      case 1:
        return _buildLabeledOptions(
          'Qual seu estilo de aprendizado preferido?',
          estilosAprendizado,
          respostas['estilo'],
          (val) => setState(() => respostas['estilo'] = val),
        );
      case 2:
        return _buildLabeledOptions(
          'Qual melhor turno para você estudar?',
          turnos,
          respostas['turno'],
          (val) => setState(() => respostas['turno'] = val),
        );
      case 3:
        return _buildLabeledOptions(
          'Quantos dias por semana você pode estudar?',
          diasSemana,
          respostas['dias'],
          (val) => setState(() => respostas['dias'] = val),
        );
      case 4:
        return _buildLabeledOptions(
          'Você prefere revisar ou simular questões?',
          ['Revisar', 'Simular', 'Ambos'],
          respostas['preferencia'],
          (val) => setState(() => respostas['preferencia'] = val),
        );
      case 5:
        return _buildDataProva();
      case 6:
        return _buildCheckboxMateriasDificeis();
      default:
        return const SizedBox();
    }
  }

  Widget _buildDataProva() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quando é sua prova?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() {
                dataProva = picked;
                respostas['dataProva'] = picked.toIso8601String();
              });
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: Text(
            dataProva == null
                ? "Selecionar data"
                : "${dataProva!.day}/${dataProva!.month}/${dataProva!.year}",
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxMateriasDificeis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quais matérias você tem mais dificuldade?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...materias.map(
          (materia) => CheckboxListTile(
            title: Text(materia, style: const TextStyle(color: Colors.white)),
            value: materiasSelecionadas.contains(materia),
            onChanged: (bool? selected) {
              setState(() {
                if (selected == true) {
                  materiasSelecionadas.add(materia);
                } else {
                  materiasSelecionadas.remove(materia);
                }
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: Colors.blue,
            checkColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledOptions(
    String pergunta,
    List<String> options,
    String? selected,
    Function(String) onSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pergunta,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...options.map(
          (opt) => Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => onSelected(opt),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    selected == opt ? Colors.blue : Colors.transparent,
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(opt, style: const TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A2B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
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
              const SizedBox(height: 40),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: _buildCustomQuestion(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (modoEscolhido == null) return;

                    if (_currentStep < 6) {
                      _nextStep();
                    } else {
                      if (modoEscolhido == 'padrao') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OrbyIntroScreen(),
                          ),
                        );
                      } else {
                        _salvarRespostas();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  child: Text(
                    _currentStep < 6 ? "Próximo" : "Finalizar",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
