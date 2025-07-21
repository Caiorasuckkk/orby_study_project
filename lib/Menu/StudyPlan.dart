import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudyPlanScreen extends StatefulWidget {
  const StudyPlanScreen({super.key});

  @override
  State<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends State<StudyPlanScreen>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  DateTime hoje = DateTime.now();

  final List<String> tarefasDoDia = [
    'Revisar resumo de funções do 1º grau',
    'Assistir vídeo: "Funções explicadas em 10min"',
    'Praticar 5 questões',
    'Realizar mini simulado no app',
  ];

  final List<bool> tarefasConcluidas = [false, false, false, false];

  String planoGerado = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initTimer();
    _initAnimation();
    _carregarPlanoDeEstudo();
  }

  Future<void> _carregarPlanoDeEstudo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .doc('usuarios/${user.uid}/Objetivo/Estudos')
          .get();

      if (doc.exists && doc.data()!.containsKey('PlanoIA')) {
        setState(() {
          planoGerado = doc['PlanoIA'];
          isLoading = false;
        });
      } else {
        setState(() {
          planoGerado = 'Plano não encontrado.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        planoGerado = 'Erro ao carregar o plano: $e';
        isLoading = false;
      });
    }
  }

  void _initTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() {
        hoje = DateTime.now();
      });
    });
  }

  void _initAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 8, end: 16).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  List<Map<String, String>> gerarCronograma() {
    final dias = <Map<String, String>>[];
    for (int i = -1; i < 5; i++) {
      final data = hoje.add(Duration(days: i));
      final diaSemana =
      ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'][data.weekday % 7];
      dias.add({
        'data': '${data.day}/${data.month}',
        'dia': diaSemana,
        'tarefa': [
          'Revisar Matemática',
          'Assistir vídeo de Química',
          'Exercícios de Redação'
        ][Random().nextInt(3)],
        'fullDate': data.toIso8601String(),
      });
    }
    return dias;
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cronograma = gerarCronograma();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1A2B),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.deepPurpleAccent,
        child: const Icon(Icons.bolt, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0D1A2B),
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Estudos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Alimentação',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.self_improvement),
            label: 'Hábitos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Treino',
          ),
        ],
        onTap: (index) {},
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset('assets/images/orby_semtxt.png', height: 50),
                      const SizedBox(width: 8),
                      const Text('Orbyt',
                          style: TextStyle(
                              fontSize: 26,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.white),
                    onPressed: () {},
                  )
                ],
              ),
              const SizedBox(height: 20),
              const Text('Próximos dias:',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: cronograma.length,
                  itemBuilder: (_, index) {
                    final dia = cronograma[index];
                    final dataItem = DateTime.parse(dia['fullDate']!);
                    final bool isHoje = dataItem.day == hoje.day &&
                        dataItem.month == hoje.month &&
                        dataItem.year == hoje.year;
                    final bool isPassado = dataItem.isBefore(hoje);

                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(dia['dia']!,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500)),
                              ),
                              if (isHoje)
                                AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (_, child) {
                                    return Container(
                                      width: _pulseAnimation.value,
                                      height: _pulseAnimation.value,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.green,
                                      ),
                                    );
                                  },
                                )
                              else if (isPassado)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(dia['data']!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(dia['tarefa']!,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ),
                          const Align(
                            alignment: Alignment.bottomRight,
                            child: Icon(Icons.arrow_forward_ios,
                                color: Colors.white54, size: 14),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text('Seu Plano de Estudos:',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 12),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: SelectableText(
                  planoGerado,
                  style:
                  const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
