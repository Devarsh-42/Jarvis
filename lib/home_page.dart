import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:jarvis/featurebox.dart';
import 'package:jarvis/open_ai_services.dart';
import 'package:jarvis/pallet.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:lottie/lottie.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum TtsState { playing, stopped }

class _HomePageState extends State<HomePage> {
  final SpeechToText speechToText = SpeechToText();
  String lastWords = "";
  final API_SERVICES api_services = API_SERVICES();
  FlutterTts flutterTts = FlutterTts();
  String? generatedContent;
  String? generatedImageUrl;
  final TextEditingController _textController = TextEditingController();
  String selectedModel = "DeepSeek V3"; // Default selected model
  TtsState _ttsState = TtsState.stopped;
  bool isLoading = false; // New flag to track loading state

  // List of available models with their logos
  final List<Map<String, dynamic>> models = [
    {"name": "DeepSeek V3", "logo": "assets/images/deepseek_logo.png"},
    {"name": "Gemini Flash 2.0 Pro", "logo": "assets/images/gemini_logo.png"},
    {"name": "Perplexity", "logo": "assets/images/perplexity_logo.png"},
    {"name": "ChatGPT", "logo": "assets/images/chatgpt_logo.png"},
  ];

  @override
  void initState() {
    super.initState();
    initSpeechtoText();
    initTextToSpeech();

    // Flutter TTS handlers
    flutterTts.setStartHandler(() {
      setState(() {
        print("TTS is playing");
        _ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("TTS completed");
        _ttsState = TtsState.stopped;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        print("TTS canceled");
        _ttsState = TtsState.stopped;
      });
    });
  }

  Future<void> initSpeechtoText() async {
    await speechToText.initialize();
    setState(() {});
  }

  Future<void> initTextToSpeech() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> startListening() async {
    await speechToText.listen(onResult: onSpeechResult);
    setState(() {});
  }

  Future<void> stopListening() async {
    await speechToText.stop();
    setState(() {});
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      lastWords = result.recognizedWords;
      _textController.text = lastWords;
    });
    print("Recognized speech: $lastWords");
  }

  Future<void> speak(String text) async {
    print("Speaking: $text");
    await flutterTts.speak(text);
  }

  Future<void> stopSpeaking() async {
    var result = await flutterTts.stop();
    if (result == 1) {
      print("Speaking stopped: true");
    } else {
      print("Speaking stopped: false");
    }
  }

  Future<void> processInput() async {
    if (_textController.text.isEmpty) return;

    String userInput = _textController.text;
    _textController.clear();
    print("Processing input: $userInput");

    // Set loading flag true and update UI
    setState(() {
      isLoading = true;
      generatedContent = null;
      generatedImageUrl = null;
    });

    final responseText =
        await api_services.processPrompt(userInput, selectedModel);
    print("API response: $responseText");

    if (responseText.contains("https://")) {
      generatedImageUrl = responseText;
      generatedContent = null;
    } else {
      generatedContent = responseText;
      generatedImageUrl = null;
      await speak(responseText);
    }

    // Reset loading flag after response is processed
    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    speechToText.stop();
    flutterTts.stop();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Jarvis',
          style: TextStyle(fontFamily: "Michroma"),
        ),
        centerTitle: true,
        leading: const Icon(Icons.menu),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Voice Assistant Icon
                  Stack(
                    children: [
                      Center(
                        child: Container(
                          height: 120,
                          width: 120,
                          margin: const EdgeInsets.only(top: 5),
                          decoration: BoxDecoration(
                            color: Pallete.backgroundColor,
                            borderRadius: BorderRadius.circular(60),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Pallete.backgroundColor,
                            borderRadius: BorderRadius.circular(60),
                            image: const DecorationImage(
                              image: AssetImage(
                                  "assets/images/jarvis_logo_removebg.png"),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  // Chat Bubble / Loading Animation
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    margin: const EdgeInsets.only(
                        top: 30, bottom: 10, left: 30, right: 10),
                    decoration: BoxDecoration(
                      color: Pallete.cardColor,
                      border: Border.all(color: Pallete.borderColor),
                      borderRadius: BorderRadius.circular(20)
                          .copyWith(topLeft: Radius.zero),
                    ),
                    child: isLoading
                        ? Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Lottie.asset(
                            "assets/new_loading_animation.json",
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover, // Ensure proper scaling
                            repeat: true, // Ensure looping
                            animate: true, // Ensure it plays
                            onLoaded: (composition) {
                              print("Lottie animation loaded successfully.");
                            },
                          ),
                        )
                        : Text(
                            generatedContent ??
                                "Hello, I'm Jarvis. How can I help you today?",
                            style: TextStyle(
                                fontSize: generatedContent == null ? 20 : 18,
                                fontFamily: "Michroma"),
                          ),
                  ),
                  // Display image if an image URL is generated.
                  if (generatedImageUrl != null)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(generatedImageUrl!),
                        ),
                      ),
                    ),
                  Visibility(
                    visible: generatedContent == null && !isLoading,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(top: 5, left: 5),
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        "Here are Few Key Features",
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: "Michroma",
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 49, 140, 193),
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: generatedContent == null && !isLoading,
                    child: Column(
                      children: const [
                        Featurebox(
                          color: Pallete.secondSuggestionBoxColor,
                          title: "Jarvis",
                          description:
                              "Jarvis is a virtual & voice assistant that can help you with your daily tasks, So that you can become Tony Stark of your life.",
                        ),
                        Featurebox(
                          color: Pallete.firstSuggestionBoxColor,
                          title: "ChatGPT",
                          description:
                              "ChatGPT 3 is an LLM that has been trained to generate human-like responses to given prompts.",
                        ),
                        Featurebox(
                          color: Pallete.thirdSuggestionBoxColor,
                          title: "Dall-E",
                          description:
                              "DALL·E is an Text-to-Image Transformer that generates images from textual descriptions.",
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // New ChatBox at the bottom
          Container(
            decoration: BoxDecoration(
              color: Pallete.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
            child: Row(
              children: [
                // Model selection dropdown
                Container(
                  margin: const EdgeInsets.only(right: 8.0),
                  decoration: BoxDecoration(
                    color: Pallete.borderColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: PopupMenuButton<String>(
                    icon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          models.firstWhere((model) =>
                              model["name"] == selectedModel)["logo"],
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                    onSelected: (String value) {
                      setState(() {
                        selectedModel = value;
                      });
                    },
                    itemBuilder: (BuildContext context) {
                      return models.map((model) {
                        return PopupMenuItem<String>(
                          value: model["name"],
                          child: Row(
                            children: [
                              Image.asset(
                                model["logo"],
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 10),
                              Text(model["name"]),
                            ],
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                // Text input field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Pallete.borderColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Ask anything...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: processInput,
                        ),
                      ),
                      onSubmitted: (_) => processInput(),
                    ),
                  ),
                ),
                // Mic button
                Container(
                  margin: const EdgeInsets.only(left: 8.0),
                  decoration: BoxDecoration(
                    color: speechToText.isListening
                        ? Colors.red
                        : Pallete.accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _ttsState == TtsState.playing ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      if (_ttsState == TtsState.playing) {
                        stopSpeaking();
                      } else {
                        if (await speechToText.hasPermission &&
                            !speechToText.isListening) {
                          await startListening();
                        } else if (speechToText.isListening) {
                          await stopListening();
                          await processInput();
                        } else {
                          await initSpeechtoText();
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
