import 'package:flutter/material.dart';
import 'dart:math';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/vocabulary.dart';

class QuizScreen extends StatefulWidget {
  final List<Vocabulary> vocabularies;
  final bool isMeaningToWord; // true: 뜻 -> 단어, false: 단어 -> 뜻

  const QuizScreen({
    Key? key,
    required this.vocabularies,
    this.isMeaningToWord = false,
  }) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<Vocabulary> shuffledVocabularies;
  late List<List<String>> quizzes;
  late List<String?> userAnswers;
  late int currentIndex;
  int correctCount = 0;
  String? selectedAnswer;
  bool answered = false;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    currentIndex = 0;
    shuffledVocabularies = List.from(widget.vocabularies)..shuffle();
    quizzes = _generateQuizzes();
    userAnswers = List.filled(shuffledVocabularies.length, null);
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage('ko-KR'); // 기본 피드백 언어는 한국어
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.2); // 여성스럽고 밝은 톤을 위해 음높이 상향
  }

  Future<void> _speakFeedback(String text, {bool isSuccess = true}) async {
    // 정답 피드백은 한국어로 설정
    await flutterTts.setLanguage('ko-KR');
    await flutterTts.setPitch(isSuccess ? 1.25 : 1.1); // 성공 시 밝은 톤(기계음 감소), 실패 시 다정한 톤
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  List<List<String>> _generateQuizzes() {
    final quizzes = <List<String>>[];
    // 모든 사용 가능한 고유 선택지를 미리 추출하여 무한 루프를 방지합니다.
    final allAvailableOptions = shuffledVocabularies
        .map((v) => widget.isMeaningToWord ? v.word : v.meaning)
        .toSet()
        .toList();

    for (final vocab in shuffledVocabularies) {
      final correctOption = widget.isMeaningToWord ? vocab.word : vocab.meaning;
      final options = [correctOption];
      final random = Random();

      // 선택 가능한 고유 단어 수가 4개보다 적을 수 있으므로 목표 개수를 조절합니다.
      final targetCount = min(4, allAvailableOptions.length);

      while (options.length < targetCount) {
        final randomOption = allAvailableOptions[random.nextInt(allAvailableOptions.length)];
        if (!options.contains(randomOption)) {
          options.add(randomOption);
        }
      }
      options.shuffle();
      quizzes.add(options);
    }
    return quizzes;
  }

  void _speakConsolation() {
    final messages = [
      "아쉬워요, 힘내세요!",
      "괜찮아요, 다음엔 맞춰요!",
      "아까워요, 다시 집중!",
      "아쉽네요, 할 수 있어요!",
      "괜찮아요, 반복해봐요!"
    ];
    final randomMessage = messages[Random().nextInt(messages.length)];
    _speakFeedback(randomMessage, isSuccess: false);
  }

  Future<void> answerQuestion(String answer) async {
    if (answered) return;

    setState(() {
      selectedAnswer = answer;
      userAnswers[currentIndex] = answer;
      answered = true;
      final correctOption = widget.isMeaningToWord ? shuffledVocabularies[currentIndex].word : shuffledVocabularies[currentIndex].meaning;
      if (answer == correctOption) {
        correctCount++;
        _speakFeedback("정답이에요! 정말 대단해요!");
      } else {
        _speakConsolation();
      }
    });

    // 정답/오답 색상을 확인할 수 있도록 0.6초 대기 후 자동으로 다음 문제로 이동
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      nextQuestion();
    }
  }

  void nextQuestion() {
    if (currentIndex < shuffledVocabularies.length - 1) {
      setState(() {
        currentIndex++;
        selectedAnswer = null;
        answered = false;
      });
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('완료!'),
          content: Text(
            '$correctCount / ${shuffledVocabularies.length} 정답\n'
            '정확도: ${(correctCount / shuffledVocabularies.length * 100).toStringAsFixed(1)}%',
          ),
          actions: [
            TextButton(
              onPressed: () {
                String detail = "\n\n[퀴즈 상세 결과]\n";
                for (int i = 0; i < shuffledVocabularies.length; i++) {
                  final correctOption = widget.isMeaningToWord ? shuffledVocabularies[i].word : shuffledVocabularies[i].meaning;
                  final question = widget.isMeaningToWord ? shuffledVocabularies[i].meaning : shuffledVocabularies[i].word;
                  String status = userAnswers[i] == correctOption ? "O" : "X";
                  detail += "${i + 1}. $question\n";
                  detail += "   - 선택: ${userAnswers[i]}\n";
                  detail += "   - 정답: $correctOption ($status)\n";
                }
                Share.share('나의 영단어 퀴즈 결과: ${shuffledVocabularies.length}문제 중 $correctCount문제 정답! 정확도: ${(correctCount / shuffledVocabularies.length * 100).toStringAsFixed(1)}%$detail');
              },
              child: const Text('공유하기'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('돌아가기'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vocabulary = shuffledVocabularies[currentIndex];
    final options = quizzes[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('퀴즈'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${currentIndex + 1} / ${shuffledVocabularies.length}'),
                    Text(
                      '정답: $correctCount',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (currentIndex + 1) / shuffledVocabularies.length,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.isMeaningToWord ? '다음 뜻에 맞는 단어는?' : '다음 단어의 뜻은?',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        Text(widget.isMeaningToWord ? vocabulary.meaning : vocabulary.word,
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final correctOption = widget.isMeaningToWord ? vocabulary.word : vocabulary.meaning;
                      final isCorrect = option == correctOption;
                      final isSelected = selectedAnswer == option;

                      Color backgroundColor = Colors.white;
                      if (answered && isCorrect) {
                        backgroundColor = Colors.green.shade100;
                      } else if (answered && isSelected && !isCorrect) {
                        backgroundColor = Colors.red.shade100;
                      } else if (!answered && isSelected) {
                        backgroundColor = Colors.blue.shade100;
                      }

                      return GestureDetector(
                        onTap: () => answerQuestion(option),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300, width: 2),
                            ),
                            child: Row(
                              children: [
                                Text(String.fromCharCode(65 + index), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                const SizedBox(width: 16),
                                Expanded(child: Text(option, style: const TextStyle(fontSize: 16))),
                                if (answered && isCorrect) const Icon(Icons.check_circle, color: Colors.green),
                                if (answered && isSelected && !isCorrect) const Icon(Icons.cancel, color: Colors.red),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // 다음 버튼을 제거하고 하단 여백을 위해 SizedBox 추가
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
