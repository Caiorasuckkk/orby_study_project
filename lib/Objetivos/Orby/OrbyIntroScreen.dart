import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../Menu/StudyPlan.dart';
 // Certifique-se de ajustar o caminho conforme sua estrutura

class OrbyIntroScreen extends StatefulWidget {
  const OrbyIntroScreen({super.key});

  @override
  State<OrbyIntroScreen> createState() => _OrbyIntroScreenState();
}

class _OrbyIntroScreenState extends State<OrbyIntroScreen> {
  final TextEditingController nomeController = TextEditingController();
  String? corSelecionada;
  String? avatarSelecionado;

  final List<String> cores = [
    'Azul',
    'Verde',
    'Roxo',
    'Amarelo',
    'Rosa',
    'Laranja',
    'Ciano',
  ];

  final Map<String, Color> corMap = {
    'Azul': Colors.blue,
    'Verde': Colors.green,
    'Roxo': Colors.purple,
    'Amarelo': Colors.amber[700]!,
    'Rosa': Colors.pink[400]!,
    'Laranja': Colors.deepOrange,
    'Ciano': Colors.cyan[600]!,
  };

  final List<String> avatares = List.generate(
    9,
        (index) => 'assets/images/orby_base${index + 1}.png',
  );

  Future<void> _salvarPersonalizacao() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final avatarFinal = avatarSelecionado!
        .split('/')
        .last
        .replaceAll('.png', '');

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('Assistente')
        .doc('orbyt')
        .set({
      'nome': nomeController.text.trim(),
      'cor': corSelecionada,
      'avatar': avatarFinal,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orby personalizado com sucesso!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudyPlanScreen()),
      );
    }
  }

  Widget _colorFilteredAvatar(String cor, String caminhoImagem) {
    final selectedColor = corMap[cor]!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          selectedColor.withOpacity(0.6),
          BlendMode.srcATop,
        ),
        child: Image.asset(
          caminhoImagem,
          height: 140,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFormValid = nomeController.text.isNotEmpty &&
        corSelecionada != null &&
        avatarSelecionado != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1A2B),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
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
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Visualização do Orby:',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: (corSelecionada != null && avatarSelecionado != null)
                    ? _colorFilteredAvatar(corSelecionada!, avatarSelecionado!)
                    : Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Selecione um avatar',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nome do seu assistente:',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nomeController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white12,
                  hintText: 'Ex: Orbyt',
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(40)),
                ),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Escolha a cor do Orby:',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: cores.map((cor) {
                  final isSelected = corSelecionada == cor;
                  return ChoiceChip(
                    label: Text(cor),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() => corSelecionada = selected ? cor : null);
                    },
                    selectedColor: corMap[cor],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: Colors.white,
                    shape: const StadiumBorder(side: BorderSide(color: Colors.white)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Escolha um avatar:',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 130,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: avatares.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final avatar = avatares[index];
                    return GestureDetector(
                      onTap: () => setState(() => avatarSelecionado = avatar),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          border: Border.all(
                            color: avatarSelecionado == avatar
                                ? const Color(0xFF4A90E2)
                                : Colors.white,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Image.asset(
                          avatar,
                          height: 80,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isFormValid ? _salvarPersonalizacao : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                  ),
                  child: const Text(
                    'Salvar e Continuar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
