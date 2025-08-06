import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'exerci.dart';

class AulasScreen extends StatefulWidget {
  final String submateria;
  final String materia;

  const AulasScreen({super.key, required this.submateria, required this.materia});

  @override
  State<AulasScreen> createState() => _AulasScreenState();
}

class _AulasScreenState extends State<AulasScreen> {
  String? aula;
  bool isLoading = true;
  bool showChat = false;
  List<Map<String, String>> videos = [];
  int currentPage = 0;
  String? orbyAvatar;
  String? orbyNome;
  String? orbyCor;
  List<Map<String, String>> messages = [];
  final TextEditingController chatController = TextEditingController();
  final PageController _pageController = PageController(viewportFraction: 0.8);

  @override
  void initState() {
    super.initState();
    buscarAula();
    buscarVideos(widget.submateria);
    buscarOrbyDoUsuario();
    _pageController.addListener(() {
      setState(() {
        currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  Future<void> buscarOrbyDoUsuario() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    if (userDoc.exists) {
      setState(() {
        orbyAvatar = userDoc.data()?['orby_avatar'];
        orbyNome = userDoc.data()?['orby_nome'];
        orbyCor = userDoc.data()?['orby_cor'];
      });
    }
  }

  Future<void> buscarAula() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('Estudo')
          .doc(widget.materia)
          .collection(widget.materia)
          .doc(widget.submateria);

      final subDoc = await docRef.get();

      if (subDoc.exists && subDoc.data()?['aula'] != null) {
        setState(() {
          aula = subDoc.data()!['aula'];
          isLoading = false;
        });
      } else {
        setState(() {
          aula = 'Aula não encontrada.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        aula = 'Erro ao carregar aula: $e';
        isLoading = false;
      });
    }
  }

  Future<void> buscarVideos(String query) async {
    final apiKey = 'AIzaSyDSROfs6aUzkeDFkg89mjkAsUbVN6Mdzo8';
    final url =
        'https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=10&q=$query%20explica%C3%A7%C3%A3o&key=$apiKey&type=video';

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    final List items = data['items'] ?? [];
    setState(() {
      videos = items.take(4).map<Map<String, String>>((item) {
        return {
          'title': item['snippet']['title'],
          'thumbnail': item['snippet']['thumbnails']['high']['url'],
          'videoId': item['id']['videoId'],
        };
      }).toList();
    });
  }

  Future<void> enviarPergunta(String pergunta) async {
    setState(() => messages.add({"role": "user", "content": pergunta}));

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['OPENAI_API_KEY']}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {
              "role": "system",
              "content": "Você é o Orby, um assistente que ajuda com dúvidas sobre: ${widget.submateria}"
            },
            ...messages,
            {"role": "user", "content": pergunta},
          ],
          "temperature": 0.7
        }),
      );

      final resposta = jsonDecode(response.body)["choices"][0]["message"]["content"];

      setState(() => messages.add({"role": "assistant", "content": resposta}));
    } catch (e) {
      setState(() => messages.add({
        "role": "assistant",
        "content": "Ocorreu um erro ao obter a resposta. Tente novamente."
      }));
    }
  }
  Color? _getOrbyColor() {
    if (orbyCor == null) return null;

    switch (orbyCor?.toLowerCase()) {
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Image.asset('assets/images/orby_semtxt.png', height: 40),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Orbyt', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Explicação:', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: const Color(0xFF1F2F3F), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey, width: 0.5)),
              padding: const EdgeInsets.all(16),
              child: Text(aula ?? '', style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => setState(() => showChat = !showChat),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    if (orbyAvatar != null)
                      Image.asset(
                        orbyAvatar!,
                        height: 50,
                        color: _getOrbyColor(), // Aplica a cor correta ao ícone do Orby
                      )
                    else
                      const Icon(Icons.android, size: 30, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tire dúvidas com $orbyNome sobre a aula!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Icon(
                      showChat ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),

            if (showChat)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...messages.map((m) {
                      final isUser = m['role'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.blueAccent : Colors.grey[700],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isUser && orbyAvatar != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: CircleAvatar(
                                    backgroundImage: AssetImage(orbyAvatar!),
                                    backgroundColor: Colors.transparent,
                                    radius: 16,
                                  ),
                                ),
                              Flexible(
                                child: Text(
                                  m['content'] ?? '',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: chatController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.black12,
                              hintText: 'Digite sua dúvida...',
                              hintStyle: const TextStyle(color: Colors.white54),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () {
                            final pergunta = chatController.text.trim();
                            if (pergunta.isNotEmpty) {
                              chatController.clear();
                              enviarPergunta(pergunta);
                            }
                          },
                        )
                      ],
                    )
                  ],
                ),
              ),
            const SizedBox(height: 24),
            const Text('Vídeos recomendados:', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (videos.isNotEmpty)
              SizedBox(
                height: 230,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: videos.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildVideoCard(videos[index]),
                  ),
                ),
              )
            else
              const Center(child: Text("Nenhum vídeo encontrado.", style: TextStyle(color: Colors.white))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExerciciosScreen(
                        materia: widget.materia,
                        submateria: widget.submateria,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Exercícios',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(Map<String, String> video) {
    return GestureDetector(
      onTap: () {
        final videoId = video['videoId']!;
        showDialog(
          context: context,
          builder: (context) => YoutubePlayerDialog(videoId: videoId),
        );
      },
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF1F2F3F), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white, width: 2)),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(video['thumbnail']!, height: 140, width: double.infinity, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(video['title']!, style: const TextStyle(color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class YoutubePlayerDialog extends StatefulWidget {
  final String videoId;

  const YoutubePlayerDialog({super.key, required this.videoId});

  @override
  State<YoutubePlayerDialog> createState() => _YoutubePlayerDialogState();
}

class _YoutubePlayerDialogState extends State<YoutubePlayerDialog> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );
  }

  @override
  void dispose() {
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.black,
      child: YoutubePlayerBuilder(
        player: YoutubePlayer(controller: _controller),
        builder: (context, player) {
          return Stack(
            children: [
              Center(child: player),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
