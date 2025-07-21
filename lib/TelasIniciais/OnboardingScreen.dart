import 'package:flutter/material.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      'title': 'Tenha um Plano Personalizado Para Cada Tarefa',
      'image': 'assets/images/ob2.png',
    },
    {
      'title': 'Monte Seus Treinos',
      'image': 'assets/images/ob2.png',
    },
    {
      'title': 'Gerencie uma Boa Alimentacao',
      'image': 'assets/images/ob3.png',
    },
    {
      'title': 'Organize Seus Estudos',
      'image': 'assets/images/ob3.png',
    },
    {
      'title': 'Tenha Bons Habitos',
      'image': 'assets/images/ob5.png',
    },
  ];

  void _nextPage() {
    if (_currentPage < onboardingData.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Widget _buildIndicator(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: _currentPage == index ? 14 : 10,
      height: _currentPage == index ? 14 : 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index ? const Color(0xFF4A90E2) : Colors.grey[400],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView.builder(
        controller: _controller,
        itemCount: onboardingData.length + 1, // Adiciona uma "página fantasma"
        onPageChanged: (index) {
          if (index == onboardingData.length) {
            // Última + 1 → vai pra tela de login
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          } else {
            setState(() => _currentPage = index);
          }
        },
        itemBuilder: (context, index) {
          if (index == onboardingData.length) {
            // Página extra não renderiza nada visível
            return const SizedBox.shrink();
          }

          final item = onboardingData[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  item['title']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: Center(
                    child: Image.asset(
                      item['image']!,
                      fit: BoxFit.contain,
                      height: 250,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    onboardingData.length,
                        (index) => _buildIndicator(index),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Próximo",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
