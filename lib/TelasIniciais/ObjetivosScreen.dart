import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Objetivos/AlimentacaoScreen.dart';
import '../Objetivos/EstudosScreen.dart';
import '../Objetivos/HabitosScreen.dart';
import '../Objetivos/Opload.dart';
import '../Objetivos/TreinoScreen.dart';

class ObjetivoScreen extends StatefulWidget {
  const ObjetivoScreen({super.key});

  @override
  State<ObjetivoScreen> createState() => _ObjetivoScreenState();
}

class _ObjetivoScreenState extends State<ObjetivoScreen> {
  String primeiroNome = '';
  String objetivoSelecionado = '';

  final List<String> opcoesObjetivo = [
    'Criar Bons Habitos',
    'Organizar Alimentacao',
    'Melhorar Estudos',
    'Montar Um Treino',
  ];

  @override
  void initState() {
    super.initState();
    _buscarPrimeiroNome();
  }

  Future<void> _buscarPrimeiroNome() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
      setState(() {
        primeiroNome = doc['primeiro_nome'] ?? '';
      });
    }
  }



  Widget _buildObjetivoButton(String texto) {
    final bool isSelected = texto == objetivoSelecionado;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            setState(() => objetivoSelecionado = texto);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? const Color(0xFF0073FF) : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 13),
            side: const BorderSide(color: Colors.white, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            elevation: 0,
          ),
          child: Text(
            texto,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _irParaProximaTela() {
    switch (objetivoSelecionado) {
      case 'Criar Bons Habitos':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitosScreen()));
        break;
      case 'Organizar Alimentacao':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AlimentacaoScreen()));
        break;
      case 'Melhorar Estudos':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EstudosScreen()));
        break;
      case 'Montar Um Treino':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MontarTreinoScreen()));
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecione um objetivo.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A2B),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: salvarConteudoConjuntos,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text("Salvar conteúdo de Conjuntos"),
                  ),
                  const SizedBox(height: 16),
                  Image.asset('assets/images/orby_semtxt.png', height: 90),
                  const SizedBox(height: 10),
                  Text(
                    'Olá, ${primeiroNome.isNotEmpty ? primeiroNome : 'Usuário'}!',
                    style: const TextStyle(
                      color: Color(0xFF4A90E2),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Qual Seu Principal\nObjetivo?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  ...opcoesObjetivo.map(_buildObjetivoButton).toList(),
                ],
              ),
            ),
            Positioned(
              bottom: 10,
              left: 24,
              right: 24,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: objetivoSelecionado.isEmpty ? null : _irParaProximaTela,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  child: const Text(
                    'Próximo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
