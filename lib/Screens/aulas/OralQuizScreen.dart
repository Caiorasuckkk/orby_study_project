import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Modelo simples de pergunta aberta para "chamada oral".
class OralQuestion {
  final String prompt;
  final String modelAnswer;
  final List<String> keywords;

  OralQuestion({
    required this.prompt,
    required this.modelAnswer,
    required this.keywords,
  });
}

class OralQuizScreen extends StatefulWidget {
  final List<OralQuestion> questions;
  final String? title;
  final bool autoStart;

  const OralQuizScreen({
    super.key,
    required this.questions,
    this.title,
    this.autoStart = true,
  });


  factory OralQuizScreen.fromSummary({
    Key? key,
    required String resumo,
    String? title,
    bool autoStart = true,
    int numQuestions = 5,
  }) {
    final qs = _QuestionFactory.buildFromSummary(resumo, maxQuestions: numQuestions);
    return OralQuizScreen(
      key: key,
      questions: qs,
      title: title ?? 'Chamada Oral',
      autoStart: autoStart,
    );
  }

  @override
  State<OralQuizScreen> createState() => _OralQuizScreenState();
}

class _OralQuizScreenState extends State<OralQuizScreen> {
  final _tts = FlutterTts();
  final _stt = stt.SpeechToText();

  int _idx = 0;
  bool _listening = false;
  bool _speaking = false;
  bool _manualStop = false;
  bool _restarting = false;
  String _transcript = '';
  String _feedback = '';
  double _confidence = 0.0;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _configureTts();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _safeAskIfAny());
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _stt.stop();
    super.dispose();
  }

  Future<void> _configureTts() async {
    await _tts.setLanguage('pt-BR');
    await _tts.setSpeechRate(0.95);
    await _tts.setPitch(1.0);
    try {
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {}
  }

  OralQuestion get _q => widget.questions[_idx];

  Future<void> _say(String text) async {
    if (!mounted) return;
    setState(() => _speaking = true);
    await _tts.stop();

    try { await _tts.awaitSpeakCompletion(true); } catch (_) {}
    await _tts.speak(text);
    if (mounted) setState(() => _speaking = false);
  }

  Future<void> _safeAskIfAny() async {
    if (widget.questions.isEmpty) return;
    await _ask();
  }

  Future<void> _ask() async {
    if (!mounted) return;
    setState(() {
      _transcript = '';
      _feedback = '';
      _confidence = 0.0;
    });
    await _say('Pergunta ${_idx + 1}. ${_q.prompt}');
    await _say('Você pode responder agora.');

    await Future.delayed(const Duration(milliseconds: 600));
    await _beginContinuousListen();
  }


  Future<void> _beginContinuousListen() async {
    _manualStop = false;

    final available = await _stt.initialize(
      onStatus: _handleStatus,
      onError: (e) {

        if (!_manualStop) _maybeRestart();
      },
      debugLogging: false,
    );
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reconhecimento de fala indisponível no dispositivo.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _listening = true;
      _transcript = '';
      _confidence = 0.0;
    });

    await _startListeningSession();
  }


  Future<void> _startListeningSession() async {
    await _stt.stop(); // limpa sessão anterior
    final started = await _stt.listen(
      localeId: 'pt_BR',
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      listenFor: const Duration(minutes: 10),
      pauseFor: const Duration(seconds: 15),
      cancelOnError: false,
      onResult: _handleResult,
      onSoundLevelChange: null,
    );

    if (!started && !_manualStop) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (!_manualStop) await _startListeningSession();
    }
  }


  Future<void> _maybeRestart() async {
    if (!mounted || _manualStop || !_listening || _restarting) return;
    _restarting = true;
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!_manualStop && _listening) {
        await _startListeningSession();
      }
    } finally {
      _restarting = false;
    }
  }

  void _handleStatus(String status) {

    if (_manualStop) return;
    if (status == 'notListening' || status == 'done' || status == 'timeout' || status == 'noMatch') {
      _maybeRestart();
    }
  }

  void _handleResult(stt.SpeechRecognitionResult r) {
    if (!mounted) return;
    final newText = r.recognizedWords.trim();
    if (newText.isEmpty) return;

    setState(() {

      if (_transcript.isEmpty) {
        _transcript = newText;
      } else if (newText.length >= _transcript.length &&
          newText.startsWith(_transcript)) {

        _transcript = newText;
      } else if (!_transcript.endsWith(newText)) {

        _transcript = '${_transcript.trim()} ${newText}'.trim();
      }
      _confidence = (r.confidence * 100.0).clamp(0.0, 100.0).toDouble();
    });
  }

  Future<void> _stopListening() async {
    _manualStop = true;
    await _stt.stop();
    if (mounted) setState(() => _listening = false);
  }

  Future<void> _stopAndEvaluate() async {
    await _stopListening();
    _evaluate();
    if (_feedback.trim().isNotEmpty) {
      await _say(_feedback);
    }
  }

  // Normaliza strings: minúsculas, remove acentos e pontuação leve.
  String _norm(String s) {
    final lower = s.toLowerCase();
    const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const to   = 'aaaaaeeeeiiiiooooouuuucn';
    var out = StringBuffer();
    for (var code in lower.runes) {
      final ch = String.fromCharCode(code);
      final idx = from.indexOf(ch);
      out.write(idx >= 0 ? to[idx] : ch);
    }
    return out.toString().replaceAll(RegExp(r'[^\w\s]'), ' ');
  }

  bool _containsWord(String text, String term) {
    final t = RegExp(r'\b' + RegExp.escape(term) + r'\b');
    return t.hasMatch(text);
  }

  void _evaluate() {
    final ansRaw = _transcript.trim();
    if (ansRaw.isEmpty) {
      setState(() {
        _feedback = 'Não consegui ouvir sua resposta. Tente falar novamente.';
      });
      return;
    }

    final ans = _norm(ansRaw);
    final keys = _q.keywords.map(_norm).where((k) => k.isNotEmpty).toList();

    int hits = 0;
    final missing = <String>[];
    for (var i = 0; i < _q.keywords.length; i++) {
      final raw = _q.keywords[i];
      final k = (i < keys.length) ? keys[i] : _norm(raw);
      if (k.isEmpty) continue;
      if (_containsWord(ans, k)) {
        hits++;
      } else {
        missing.add(raw);
      }
    }

    final coverage = keys.isEmpty ? 1.0 : hits / keys.length;

    // Faixas de feedback
    String bandMsg;
    if (coverage >= 0.85) {
      bandMsg = 'Excelente! Sua resposta está **muito alinhada** ao esperado.';
    } else if (coverage >= 0.60) {
      bandMsg = 'Bom! Você cobriu os pontos principais, mas dá pra refinar.';
    } else if (coverage >= 0.35) {
      bandMsg = 'Parcial. Alguns pontos importantes ficaram de fora.';
    } else {
      bandMsg = 'Você se afastou bastante do esperado (muito aquém).';
    }

    setState(() {
      if (coverage >= 0.60) _score++;
      final miss = missing.isEmpty ? '' : '\nFaltou mencionar: ${missing.join(", ")}.';
      _feedback = '$bandMsg$miss\n\nResposta modelo: ${_q.modelAnswer}';
    });
  }

  Future<void> _repeatQuestion() async {
    if (_listening) await _stopListening();
    await _say(_q.prompt);
  }

  Future<void> _next() async {
    if (_listening) await _stopListening();
    if (_idx < widget.questions.length - 1) {
      setState(() => _idx++);
      await _ask();
    } else {
      await _say('Parabéns! Você concluiu a chamada oral.');
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Concluído'),
          content: Text('Pontuação: $_score / ${widget.questions.length}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1A2B),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A2A3D),
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
          title: Text(widget.title ?? 'Chamada Oral',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Nenhuma pergunta disponível.\nVolte e gere as perguntas a partir do resumo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ),
      );
    }

    final progress = (_idx + 1) / widget.questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1A2B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2A3D),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(widget.title ?? 'Chamada Oral',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                color: Colors.amberAccent,
                backgroundColor: Colors.white10,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Pergunta ${_idx + 1} de ${widget.questions.length} • Pontos: $_score',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF16253A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.record_voice_over, color: Colors.amberAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _q.prompt,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_transcript.isNotEmpty) ...[
                              const Text('Sua resposta:',
                                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text(_transcript,
                                  style: const TextStyle(color: Colors.white, height: 1.35)),
                              const SizedBox(height: 6),
                              if (_confidence > 0)
                                Text('Confiança do reconhecimento: ${_confidence.toStringAsFixed(0)}%',
                                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
                              const SizedBox(height: 12),
                            ],
                            if (_feedback.isNotEmpty) ...[
                              const Text('Feedback:',
                                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text(_feedback,
                                  style: const TextStyle(color: Colors.white, height: 1.35)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                SizedBox(
                  width: 180, height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _speaking ? null : _repeatQuestion,
                    icon: const Icon(Icons.volume_up, color: Colors.white),
                    label: const Text('Repetir pergunta', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                SizedBox(
                  width: 220, height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _listening ? _stopAndEvaluate : _beginContinuousListen,
                    icon: Icon(_listening ? Icons.stop : Icons.mic, color: Colors.white),
                    label: Text(_listening ? 'Parar e avaliar' : 'Responder (mic)',
                        style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                SizedBox(
                  width: 120, height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _next,
                    icon: const Icon(Icons.navigate_next, color: Colors.white),
                    label: const Text('Próxima', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ----------------------
/// Utilitários de geração (fallback local)
/// ----------------------
class _QuestionFactory {
  static final Set<String> _stopwords = {
    'a','o','os','as','de','do','da','dos','das','um','uma','uns','umas','e','é','ser','são',
    'em','no','na','nos','nas','por','para','com','sem','entre','sobre','como','mais','menos',
    'muito','muitos','muitas','pouco','poucos','poucas','também','até','se','que','porque',
    'quando','onde','qual','quais','qualquer','cada','isso','isto','aquele','aquela','aquilo',
    'sua','seu','suas','seus','minha','meu','minhas','meus','deve','devem','pode','podem',
    'há','foi','era','foram','será','serão','tem','têm','ter','haver','já','não','sim'
  };

  static List<OralQuestion> buildFromSummary(String text, {int maxQuestions = 5}) {
    final resumo = _clean(text);
    if (resumo.isEmpty) {
      return [
        OralQuestion(
          prompt: 'O resumo está vazio. Fale brevemente sobre o tema que você estudou.',
          modelAnswer: 'Sem conteúdo fornecido.',
          keywords: const [],
        ),
      ];
    }

    final topics = _topTopics(resumo, count: 8);
    final sentences = _splitSentences(resumo);

    final List<OralQuestion> out = [];

    out.add(OralQuestion(
      prompt: 'Resuma, com suas palavras, o conteúdo estudado destacando os pontos centrais.',
      modelAnswer: _clip(resumo, 220),
      keywords: topics.take(5).toList(),
    ));

    final patterns = <String>[
      'Explique o conceito de {x} e sua importância no contexto do material.',
      'Quais são as principais características de {x}? Dê um exemplo.',
      'Qual o papel de {x} no tema estudado? Comente causas e consequências.',
      'Compare {x} com outro conceito relacionado presente no resumo.',
      'Cite vantagens, limitações ou desafios associados a {x}.'
    ];

    int created = 0;
    for (final t in topics) {
      if (created >= (maxQuestions - 1)) break;
      final template = patterns[created % patterns.length];
      final qText = template.replaceAll('{x}', t);
      final ans = _sentenceContaining(sentences, t) ?? _clip(resumo, 200);

      out.add(OralQuestion(
        prompt: qText,
        modelAnswer: ans,
        keywords: _keywordsForTopic(t, sentences),
      ));
      created++;
    }

    if (out.isEmpty) {
      out.add(OralQuestion(
        prompt: 'Fale sobre o principal tema do resumo, dando exemplos.',
        modelAnswer: _clip(resumo, 220),
        keywords: topics.take(5).toList(),
      ));
    }

    return out.take(maxQuestions).toList();
  }

  static String _clean(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

  static List<String> _splitSentences(String s) {
    final parts = s.split(RegExp(r'(?<=[\.\?\!])\s+'));
    return parts.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  static List<String> _tokenize(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-záàâãéèêíïóôõöúçñ0-9\s\-]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 3 && !_stopwords.contains(w))
        .toList();
  }

  static List<String> _topTopics(String s, {int count = 8}) {
    final toks = _tokenize(s);
    final freq = <String,int>{};
    for (final w in toks) {
      if (RegExp(r'^\d+$').hasMatch(w)) continue;
      freq[w] = (freq[w] ?? 0) + 1;
    }
    final sorted = freq.entries.toList()
      ..sort((a,b) => b.value.compareTo(a.value));
    final List<String> topics = [];
    for (final e in sorted) {
      if (topics.every((t) => t != e.key)) topics.add(e.key);
      if (topics.length >= count) break;
    }
    return topics;
  }

  static String? _sentenceContaining(List<String> sentences, String term) {
    final t = term.toLowerCase();
    for (final s in sentences) {
      if (s.toLowerCase().contains(t)) {
        return s.length > 240 ? _clip(s, 240) : s;
      }
    }
    return null;
  }

  static List<String> _keywordsForTopic(String topic, List<String> sentences) {
    final base = <String>{};
    for (final part in topic.split(RegExp(r'[\s\-_/]'))) {
      if (part.trim().length >= 3) base.add(part.trim());
    }
    final sent = _sentenceContaining(sentences, topic);
    if (sent != null) {
      final toks = _tokenize(sent);
      for (final w in toks) {
        if (base.length >= 5) break;
        base.add(w);
      }
    }
    return base.take(5).toList();
  }

  static String _clip(String s, int max) {
    if (s.length <= max) return s;
    return s.substring(0, max).trimRight() + '…';
  }
}
