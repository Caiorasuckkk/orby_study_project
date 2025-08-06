import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/firebase_service.dart';
import '../Redacao/RedacaoIntroScreen.dart';
import '../Simulados/SimuladoIntroScreen.dart';
import 'widgets/area_blocos.dart';

class StudyPlanScreen extends StatefulWidget {
  const StudyPlanScreen({super.key});

  @override
  State<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends State<StudyPlanScreen> {
  bool isLoading = true;
  Map<String, List<String>> topicosPorMateria = {};
  Map<String, dynamic> resultados = {};
  String nomeUsuario = '';
  String orbyNome = '';
  String orbyCor = '';
  String orbyAvatar = '';

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
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    setState(() => isLoading = true);

    final info = await FirebaseService.getUsuarioInfo();
    if (info != null) {
      nomeUsuario = info['nomeCompleto'];
      orbyNome = info['orby_nome'];
      orbyCor = info['orby_cor'];
      orbyAvatar = info['orby_avatar'];
    }

    final dados = await FirebaseService.getTopicosPorMateria(areaPorMateria);
    if (dados.isNotEmpty) {
      topicosPorMateria = Map<String, List<String>>.from(dados['topicos']);
      resultados = Map<String, dynamic>.from(dados['resultados']);
    }
    setState(() => isLoading = false);
  }


  Color _getOrbyColor() {
    switch (orbyCor.toLowerCase()) {
      case 'azul':
        return Colors.blueAccent;
      case 'verde':
        return Colors.green;
      case 'roxo':
        return Colors.deepPurple;
      case 'vermelho':
        return Colors.redAccent;
      case 'rosa':
        return Colors.pinkAccent;
      case 'amarelo':
        return Colors.amber;
      case 'laranja':
        return Colors.orangeAccent;
      default:
        return Colors.tealAccent.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A2B),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
              const SizedBox(height: 16),
              if (nomeUsuario.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2A3D),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade500, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: Image.asset(
                              orbyAvatar.isNotEmpty
                                  ? orbyAvatar
                                  : 'assets/images/orby_base2.png',
                              color: _getOrbyColor(),
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Olá, $nomeUsuario!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Eu sou $orbyNome, seu assistente!\nVamos evoluir juntos 🚀',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

              // Atividades
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2A3D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade600, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Atividades',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 230,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _atividadeCard(
                            title: 'Redação',
                            icon: Icons.edit_note,
                            descricao:
                            'Pratique sua redação semanalmente com temas atuais e receba feedback.',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RedacaoIntroScreen(),
                                ),
                              );
                            },
                          ),
                          _atividadeCard(
                            title: 'Simulado Final',
                            icon: Icons.assignment_turned_in_rounded,
                            descricao: 'Veja como se sairia em um simulado real.',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SimuladoIntroScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Plano de Estudos
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2A3D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade600, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seu Plano de Estudos:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AreaBlocos(
                      topicosPorMateria: topicosPorMateria,
                      resultados: resultados,
                      areaPorMateria: areaPorMateria,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _atividadeCard({
    required String title,
    required String descricao,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1A2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade500, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.amberAccent, size: 26),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Text(
            descricao,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          ElevatedButton.icon(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.play_circle_outline, color: Colors.white),
            label: const Text(
              'Começar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
