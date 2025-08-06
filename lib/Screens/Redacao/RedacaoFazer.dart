import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Services/openai_services.dart';


class RedacaoEscreverScreen extends StatefulWidget {
  final String tema;
  final List<String> textosDeReferencia;

  const RedacaoEscreverScreen({
    super.key,
    required this.tema,
    required this.textosDeReferencia,
  });

  @override
  State<RedacaoEscreverScreen> createState() => _RedacaoEscreverScreenState();
}

class _RedacaoEscreverScreenState extends State<RedacaoEscreverScreen> {
  final TextEditingController redacaoController = TextEditingController();
  int contadorPalavras = 0;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    redacaoController.addListener(() {
      final texto = redacaoController.text.trim();
      final palavras = texto.isEmpty ? 0 : texto.split(RegExp(r'\s+')).length;
      setState(() {
        contadorPalavras = palavras;
      });
    });
  }

  Future<Map<String, dynamic>> avaliarRedacaoComIA(String tema, String texto) async {
    final prompt = '''
Você é um avaliador de redações do ENEM. Avalie a redação de acordo com os critérios do ENEM e retorne um JSON com os seguintes campos:

{
  "nota": número entre 0 e 1000,
  "pontos_melhorar": "máximo 2 frases",
  "feedback": "máximo 3 frases"
}

Tema: $tema

Redação:
$texto
''';

    try {
      final content = await chamarOpenAI(prompt);

      String cleanedContent = content
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .replaceAll(RegExp(r',\s*}'), '}')
          .trim();

      Map<String, dynamic> resultado;
      try {
        resultado = jsonDecode(cleanedContent);
      } catch (_) {
        cleanedContent = cleanedContent
            .replaceAll(RegExp(r'[^\x00-\x7F]'), '')
            .replaceAll(RegExp(r',\s*}'), '}');
        resultado = jsonDecode(cleanedContent);
      }

      return {
        "nota": resultado["nota"] ?? "N/A",
        "pontos_melhorar": resultado["pontos_melhorar"] ?? "Não informado",
        "feedback": resultado["feedback"] ?? "Não informado",
      };
    } catch (e) {
      debugPrint("Erro ao interpretar resposta da IA: $e");
      throw Exception("Erro ao interpretar resposta da IA");
    }
  }

  Future<void> salvarRedacao() async {
    final texto = redacaoController.text.trim();
    if (texto.length < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escreva pelo menos 50 caracteres.')),
      );
      return;
    }

    try {
      setState(() => isSaving = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      final resultado = await avaliarRedacaoComIA(widget.tema, texto);
      final dataFormatada = DateFormat('dd/MM/yyyy').format(DateTime.now());

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('Objetivo')
          .doc('Estudos')
          .collection('Redacao')
          .add({
        'tema': widget.tema,
        'data': dataFormatada,
        'nota': resultado['nota'],
        'pontos_melhorar': resultado['pontos_melhorar'],
        'feedback': resultado['feedback'],
        'palavras': contadorPalavras,
      });

      if (!mounted) return;

      String emoji = '';
      final nota = int.tryParse(resultado['nota'].toString()) ?? 0;
      if (nota >= 900) {
        emoji = '🥇 Excelente!';
      } else if (nota >= 700) {
        emoji = '👍 Bom trabalho!';
      } else if (nota >= 500) {
        emoji = '⚠️ Atenção!';
      } else {
        emoji = '❌ Reforçar base.';
      }

      String sugestao = nota >= 800
          ? "Leia redações nota 1000 para inspiração."
          : "Continue praticando com temas variados.";

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1F2F3F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Avaliação da Redação',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nota: ${resultado['nota']} / 1000 $emoji',
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 12),
                Text('Palavras: $contadorPalavras',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                const Text('Pontos a Melhorar:',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                Text(resultado['pontos_melhorar'],
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 12),
                const Text('Feedback:',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                Text(resultado['feedback'],
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                Text('💡 Sugestão: $sugestao',
                    style: const TextStyle(color: Colors.amberAccent)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/studyplan');
              },
              child: const Text('OK', style: TextStyle(color: Colors.amberAccent)),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Erro ao salvar ou avaliar redação: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar redação: $e')),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A2B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Row(
                children: [
                  Image.asset('assets/images/orby_semtxt.png', height: 40),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Orbyt',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Tema:',
                  style: TextStyle(color: Colors.amberAccent, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(widget.tema,
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 20),
              const Text('Textos de Apoio:',
                  style: TextStyle(color: Colors.white70, fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...widget.textosDeReferencia.map(
                    (texto) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(texto, style: const TextStyle(color: Colors.white60, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Escreva sua redação:',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2F3F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade500),
                ),
                child: TextField(
                  controller: redacaoController,
                  maxLines: 20,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration.collapsed(
                    hintText: 'Digite sua redação aqui...',
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Palavras: $contadorPalavras',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.right),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: isSaving ? null : salvarRedacao,
                icon: const Icon(Icons.save, color: Colors.white),
                label: Text(isSaving ? 'Salvando...' : 'Salvar Redação',
                    style: const TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
