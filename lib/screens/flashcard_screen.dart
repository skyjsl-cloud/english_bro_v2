import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/vocabulary.dart';

class FlashcardScreen extends StatefulWidget {
  final List<Vocabulary> vocabularies;

  const FlashcardScreen({super.key, required this.vocabularies});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late int currentIndex;
  late List<Vocabulary> shuffledVocabularies;
  bool showMeaning = false;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    currentIndex = 0;
    shuffledVocabularies = List.from(widget.vocabularies)..shuffle();
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(0.45); // 너무 느리지 않게 조절하여 자연스러움 강조
    await flutterTts.setPitch(1.2); // 기계음을 줄이기 위해 톤을 더 밝게 설정

    List<dynamic> voices = await flutterTts.getVoices;
    
    try {
      // iOS/Android에서 좀 더 고품질(Premium)이거나 여성형인 목소리 검색
      final preferredVoice = voices.firstWhere(
        (voice) {
          final name = voice['name'].toString().toLowerCase();
          return name.contains('female') || name.contains('samantha') || name.contains('kyoko');
        },
        orElse: () => voices.first,
      );

      if (preferredVoice != null) {
        await flutterTts.setVoice({
          "name": preferredVoice['name'],
          "locale": preferredVoice['locale']
        });
      }
    } catch (e) {
      debugPrint("Voice setting error: $e");
    }
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage('en-US'); // 단어는 영어로
    await flutterTts.setPitch(1.2);
    await flutterTts.speak(text);
  }

  void nextCard() {
    if (currentIndex < shuffledVocabularies.length - 1) {
      setState(() {
        currentIndex++;
        showMeaning = false;
      });
    }
  }

  void previousCard() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        showMeaning = false;
      });
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vocabulary = shuffledVocabularies[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('플래시카드'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 진행률
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${currentIndex + 1} / ${shuffledVocabularies.length}'),
                    Text(
                      '${((currentIndex + 1) / shuffledVocabularies.length * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
          // 카드
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () {
                  _speak(shuffledVocabularies[currentIndex].word);
                },
                onDoubleTap: () {
                  setState(() {
                    showMeaning = !showMeaning;
                  });
                },
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade400,
                          Colors.blue.shade600,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          showMeaning ? '뜻' : '단어',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          showMeaning ? vocabulary.meaning : vocabulary.word,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          '탭: 발음 | 더블탭: 뜻보기',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 네비게이션 버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: currentIndex > 0 ? previousCard : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('이전'),
                ),
                ElevatedButton.icon(
                  onPressed: currentIndex < shuffledVocabularies.length - 1
                      ? nextCard
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('다음'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
