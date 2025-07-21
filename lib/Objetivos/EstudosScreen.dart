import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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
  final Map<String, TextEditingController> controllers = {
    "outro": TextEditingController(),
    "experiencia": TextEditingController(),
    "motivacao": TextEditingController(),
    "dataProva": TextEditingController(),
    "curso": TextEditingController(),
    "nivel": TextEditingController(),
    "dificuldades": TextEditingController(),
  };
  DateTime? dataProva;

  final objetivos = [
    'Vestibular/Enem',
    'Faculdade',
    'Concurso',
    'Certificação',
    'Aprendizado Pessoal'
  ];

  final vestibulares = ['ENEM', 'FUVEST', 'UNICAMP', 'UNESP', 'Outros'];
  final concursos = ['INSS', 'Polícia Federal', 'Banco do Brasil', 'Outros'];
  final certificacoes = ['AWS Certified', 'Google Cloud', 'Scrum Master', 'Outros'];
  final aprendizados = ['Programação', 'Design', 'Marketing', 'Outros'];
  final horarios = ['1 hora', '2 horas', '3 horas', 'Mais de 3 horas'];

  void _nextStep() => setState(() => _currentStep++);

  Future<void> _salvarRespostas() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception("Usuário não está logado");
      }

      // Gera plano com IA
      String planoIA = await gerarPlanoEstudosComIA(respostas);

      // Salva no Firestore
      await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(uid)
          .collection("Objetivo")
          .doc("Estudos")
          .set({
        "Tipo": "Estudos",
        "Perguntas": respostas,
        "PlanoIA": planoIA, // ← Adiciona o plano
        "Gerado_em": DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Respostas salvas e plano gerado com sucesso!")),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrbyIntroScreen()));
      }
    } catch (e) {
      print("Erro ao salvar ou gerar plano: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: ${e.toString()}")),
        );
      }
    }
  }



  Widget _buildCustomQuestion() {
    if (_currentStep == 0) {
      return _buildLabeledOptions(
        'Você estuda para qual tipo de objetivo?',
        objetivos,
        objetivoEstudo,
            (val) {
          setState(() {
            objetivoEstudo = val;
            respostas['Objetivo'] = val;
            _currentStep = 0;
          });
        },
      );
    }

    switch (objetivoEstudo) {
      case 'Vestibular/Enem':
        switch (_currentStep) {
          case 1:
            return _buildWithOther(vestibulares, 'Qual vestibular você pretende prestar?', 'vestibular');
          case 2:
            return _buildYesNoField('Você já definiu um cronograma de estudos?', 'cronograma');
          case 3:
            return _buildLabeledOptions('Quantas horas por semana você pode estudar?', horarios, respostas['horas'], (val) => setState(() => respostas['horas'] = val));
          case 4:
            return _buildTextField('Quais disciplinas você considera mais difíceis?', 'dificuldades');
        }
        break;

      case 'Faculdade':
        switch (_currentStep) {
          case 1:
            return _buildTextField('Qual curso você está cursando?', 'curso');
          case 2:
            return _buildYesNoField('Você está gostando do curso?', 'gosta_curso');
          case 3:
            return _buildLabeledOptions('Quantas horas por semana você pode estudar?', horarios, respostas['horas'], (val) => setState(() => respostas['horas'] = val));
          case 4:
            return _buildTextField('Quais são suas principais dificuldades acadêmicas?', 'dificuldades');
        }
        break;

      case 'Aprendizado Pessoal':
        switch (_currentStep) {
          case 1:
            return _buildWithOther(aprendizados, 'O que você quer aprender?', 'tema');
          case 2:
            return _buildTextField('Por que você quer aprender isso?', 'motivacao');
          case 3:
            return _buildLabeledOptions('Quantas horas por semana você pode estudar?', horarios, respostas['horas'], (val) => setState(() => respostas['horas'] = val));
        }
        break;

      case 'Concurso':
        switch (_currentStep) {
          case 1:
            return _buildWithOther(concursos, 'Qual concurso você pretende prestar?', 'concurso');
          case 2:
            return _buildWithOther(['Administrativa', 'Jurídica', 'Saúde', 'Outros'], 'Área do concurso:', 'area');
          case 3:
            return _buildDataPicker();
          case 4:
            return _buildLabeledOptions('Quantas horas por semana você pode estudar?', horarios, respostas['horas'], (val) => setState(() => respostas['horas'] = val));
        }
        break;

      case 'Certificação':
        switch (_currentStep) {
          case 1:
            return _buildWithOther(certificacoes, 'Qual certificação você está buscando?', 'certificacao');
          case 2:
            return _buildWithOther(['Melhorar currículo', 'Exigência do trabalho', 'Transição de carreira'], 'Motivo:', 'motivo');
          case 3:
            return _buildTextField('Você já possui alguma experiência na área?', 'experiencia');
          case 4:
            return _buildLabeledOptions('Quantas horas por semana você pode estudar?', horarios, respostas['horas'], (val) => setState(() => respostas['horas'] = val));
        }
        break;
    }

    return const SizedBox();
  }

  Widget _buildWithOther(List<String> options, String pergunta, String key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(pergunta, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...options.map((opt) => Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => respostas[key] = opt == 'Outros' ? controllers['outro']!.text : opt),
            style: ElevatedButton.styleFrom(
              backgroundColor: respostas[key] == opt ? Colors.blue : Colors.transparent,
              side: const BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(opt, style: const TextStyle(color: Colors.white)),
          ),
        )),
        if (respostas[key] == controllers['outro']!.text || respostas[key] == 'Outros')
          TextField(
            controller: controllers['outro'],
            onChanged: (val) => setState(() => respostas[key] = val),
            decoration: _inputDecoration('Digite aqui'),
            style: const TextStyle(color: Colors.white),
          )
      ],
    );
  }

  Widget _buildLabeledOptions(String pergunta, List<String> options, String? selected, Function(String) onSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(pergunta, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...options.map((opt) => Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => onSelected(opt),
            style: ElevatedButton.styleFrom(
              backgroundColor: selected == opt ? Colors.blue : Colors.transparent,
              side: const BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(opt, style: const TextStyle(color: Colors.white)),
          ),
        ))
      ],
    );
  }

  Widget _buildTextField(String label, String key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controllers[key],
          onChanged: (val) => respostas[key] = val,
          decoration: _inputDecoration(label),
          style: const TextStyle(color: Colors.white),
        )
      ],
    );
  }

  Widget _buildYesNoField(String pergunta, String key) {
    return _buildLabeledOptions(pergunta, ['Sim', 'Não'], respostas[key], (val) => setState(() => respostas[key] = val));
  }

  Widget _buildDataPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Data da prova', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() {
                dataProva = picked;
                respostas['data_prova'] = DateFormat('dd/MM/yyyy').format(picked);
                controllers['dataProva']!.text = respostas['data_prova'];
              });
            }
          },
          child: AbsorbPointer(
            child: TextField(
              controller: controllers['dataProva'],
              decoration: _inputDecoration('Selecione a data'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Image.asset('assets/images/orby_semtxt.png', height: 70),
                  const SizedBox(width: 8),
                  const Text('Orbyt', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 40),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: _buildCustomQuestion(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    int finalStep = 4;
                    if (objetivoEstudo == 'Aprendizado Pessoal') finalStep = 3;
                    if (objetivoEstudo == 'Faculdade') finalStep = 4;
                    if (_currentStep < finalStep) {
                      _nextStep();
                    } else {
                      _salvarRespostas();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                  ),
                  child: Text(
                    (_currentStep < 4 && !(objetivoEstudo == 'Aprendizado Pessoal' && _currentStep >= 3)) ? "Próximo" : "Finalizar",
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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

Future<String> gerarPlanoEstudosComIA(Map<String, dynamic> respostas) async {
  const endpoint = 'https://api.openai.com/v1/chat/completions';
  const openAIApiKey = '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'; // 🔒 Substitua por variável segura em produção

  final prompt = '''
Sou um mentor de estudos para vestibulares. Com base nas informações fornecidas pelo aluno, crie um plano de estudos **detalhado, equilibrado e eficaz**.

🔹 Instruções:

1. Dê ênfase especial às dificuldades relatadas pelo aluno.
2. Aborde todas as disciplinas cobradas no vestibular (Matemática, Português, Redação, Química, Física, Biologia, História, Geografia, Sociologia, Filosofia, Inglês).
3. Estruture o plano por semanas, com estimativa de horas por matéria.
4. Para cada matéria, sugira:
   - Tópicos a estudar
   - Recursos recomendados (links gratuitos, como Khan Academy, Brasil Escola, Descomplica, YouTube etc.)
   - 1 ou 2 exercícios sugeridos por tema
   - Simulados online (se possível com link)

5. Inclua técnicas de revisão, memorização e prática.
6. Finalize com um resumo motivacional e estratégias personalizadas de organização.

📋 Informações do aluno:
Objetivo: ${respostas['vestibular'] ?? 'N/A'}
Dificuldades: ${respostas['dificuldades'] ?? 'Não informado'}
Horas por semana disponíveis: ${respostas['horas'] ?? 'N/A'}
Estilo de aprendizado: ${respostas['estilo'] ?? 'Não informado'}
Nível atual: ${respostas['nivel'] ?? 'N/A'}
Motivação: ${respostas['motivacao'] ?? 'N/A'}
Experiência prévia: ${respostas['experiencia'] ?? 'N/A'}
Data da prova: ${respostas['data_prova'] ?? 'N/A'}

🎯 O plano deve ter linguagem amigável, clara e visualmente bem estruturada. Use marcação por semana e matérias.
''';


  final response = await http.post(
    Uri.parse(endpoint),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $openAIApiKey',
    },
    body: jsonEncode({
      'model': 'gpt-4',
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 0.7,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'];
  } else {
    throw Exception('Erro ao gerar plano: ${response.body}');
  }
}

