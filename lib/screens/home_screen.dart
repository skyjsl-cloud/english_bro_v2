import 'package:flutter/material.dart';
import '../models/vocabulary.dart';
import '../services/vocabulary_service.dart';
import 'flashcard_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedLevel;

  @override
  Widget build(BuildContext context) {
    if (selectedLevel == null) {
      return _buildLevelSelection();
    }

    return _buildMainScreen();
  }

  Widget _buildLevelSelection() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('영단어 삼형제'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '학습할 레벨을 선택하세요',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),
            _LevelButton(
              title: '초등 필수 영단어',
              description: '초등학교 필수 영단어',
              icon: Icons.school,
              color: Colors.green,
              onPressed: () {
                setState(() => selectedLevel = 'elementary.csv');
              },
            ),
            const SizedBox(height: 16),
            _LevelButton(
              title: '중등 수능 영단어',
              description: '중학교 및 수능 필수 영단어',
              icon: Icons.book,
              color: Colors.blue,
              onPressed: () {
                setState(() => selectedLevel = 'middle.csv');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainScreen() {
    final vocabularyFuture = VocabularyService.loadVocabulary(selectedLevel!);
    final isElementary = selectedLevel == 'elementary.csv';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isElementary ? '초등 필수 영단어' : '중등 수능 영단어',
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() => selectedLevel = null);
          },
        ),
      ),
      body: FutureBuilder<List<Vocabulary>>(
        future: vocabularyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('오류: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('단어를 불러올 수 없습니다.'),
            );
          }

          final vocabularies = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 통계
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          '총 단어 수',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${vocabularies.length}개',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 플래시카드 모드
                _ModeButton(
                  title: '플래시카드',
                  description: '카드를 넘기며 단어를 학습하세요',
                  icon: Icons.style,
                  color: Colors.blue,
                  onPressed: () => _showRangeSelectionDialog(
                    context,
                    vocabularies,
                    (filtered) => FlashcardScreen(vocabularies: filtered),
                  ),
                ),
                const SizedBox(height: 16),

                // 퀴즈 모드
                _ModeButton(
                  title: '퀴즈 (단어 -> 뜻)',
                  description: '선택지에서 정답을 고르세요',
                  icon: Icons.quiz,
                  color: Colors.green,
                  onPressed: () => _showRangeSelectionDialog(
                    context,
                    vocabularies,
                    (filtered) => QuizScreen(vocabularies: filtered, isMeaningToWord: false),
                  ),
                ),
                const SizedBox(height: 16),

                // 퀴즈 모드 (뜻 -> 단어)
                _ModeButton(
                  title: '퀴즈 (뜻 -> 단어)',
                  description: '뜻을 보고 알맞은 영단어를 고르세요',
                  icon: Icons.extension,
                  color: Colors.orange,
                  onPressed: () => _showRangeSelectionDialog(
                    context,
                    vocabularies,
                    (filtered) => QuizScreen(vocabularies: filtered, isMeaningToWord: true),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showRangeSelectionDialog(
    BuildContext context,
    List<Vocabulary> vocabularies,
    Widget Function(List<Vocabulary>) destinationBuilder,
  ) {
    int start = 0;
    int end = vocabularies.length - 1;
    final startController = TextEditingController(text: '1');
    final endController = TextEditingController(text: vocabularies.length.toString());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('학습 범위 선택'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startController,
                      decoration: const InputDecoration(labelText: '시작'),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        int? s = int.tryParse(val);
                        if (s != null && s >= 1 && s <= vocabularies.length) {
                          setDialogState(() => start = s - 1);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: endController,
                      decoration: const InputDecoration(labelText: '끝'),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        int? e = int.tryParse(val);
                        if (e != null && e >= 1 && e <= vocabularies.length) {
                          setDialogState(() => end = e - 1);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              RangeSlider(
                values: RangeValues(
                  start.toDouble().clamp(0, (vocabularies.length - 1).toDouble()),
                  end.toDouble().clamp(0, (vocabularies.length - 1).toDouble()),
                ),
                min: 0,
                max: (vocabularies.length - 1).toDouble(),
                divisions: vocabularies.length > 1 ? vocabularies.length - 1 : 1,
                onChanged: (values) {
                  setDialogState(() {
                    start = values.start.toInt();
                    end = values.end.toInt();
                    startController.text = (start + 1).toString();
                    endController.text = (end + 1).toString();
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                final filtered = vocabularies.sublist(start, end + 1);
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => destinationBuilder(filtered)),
                );
              },
              child: const Text('시작'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelButton extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _LevelButton({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ModeButton({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
