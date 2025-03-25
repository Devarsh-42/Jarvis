import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:jarvis/featurebox.dart';
import 'package:jarvis/open_ai_services.dart';
import 'package:jarvis/pallet.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SpeechToText speechToText = SpeechToText();
  String lastWords = "";
  final API_SERVICES api_services = API_SERVICES();
  FlutterTts flutterTts = FlutterTts();
  String? generatedContent;
  String? generatedImageUrl;

  @override
  void initState() {
    super.initState();
    initSpeechtoText();
    initTextToSpeech();
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
    });
    print("Recognized speech: $lastWords");
  }

  Future<void> speak(String text) async {
    print("Speaking: $text");
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    speechToText.stop();
    flutterTts.stop();
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
      body: SingleChildScrollView(
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
                      color: Pallete.assistantCircleColor,
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
                        image: AssetImage("assets/images/virtualAssistant.png"),
                      ),
                    ),
                  ),
                )
              ],
            ),
            // Chat Bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              margin: const EdgeInsets.only(top: 30, bottom: 10, left: 30, right: 10),
              decoration: BoxDecoration(
                color: Pallete.cardColor,
                border: Border.all(color: Pallete.borderColor),
                borderRadius: BorderRadius.circular(20).copyWith(topLeft: Radius.zero),
              ),
              child: Text(
                generatedContent ?? "Hello, I'm Jarvis. How can I help you today?",
                style: TextStyle(
                  fontSize: generatedContent == null ? 20 : 18,
                  fontFamily: "Michroma"
                ),
              ),
            ),
            // Display image if an image URL is generated.
            if (generatedImageUrl != null)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  margin: const EdgeInsets.all(20),
                  child: ClipRRect( borderRadius:BorderRadius.circular(20), child: Image.network(generatedImageUrl!)),
                ),
              ),
            Visibility(
              visible: generatedContent == null,
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
              visible: generatedContent == null, 
              child: Column(
                children: const [
                  Featurebox(
                    color: Pallete.secondSuggestionBoxColor,
                    title: "Jarvis",
                    description: "Jarvis is a virtual & voice assistant that can help you with your daily tasks, So that you can become Tony Stark of your life.",
                  ),
                  Featurebox(
                    color: Pallete.firstSuggestionBoxColor,
                    title: "ChatGPT",
                    description: "ChatGPT 3 is an LLM that has been trained to generate human-like responses to given prompts.",
                  ),
                  Featurebox(
                    color: Pallete.thirdSuggestionBoxColor,
                    title: "Dall-E",
                    description: "DALL·E is an Text-to-Image Transformer that generates images from textual descriptions.",
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (await speechToText.hasPermission && !speechToText.isListening) {
            print("Starting listening, lastWords: $lastWords");
            await startListening();
          } else if (speechToText.isListening) {
            print("Processing recognized words: $lastWords");
            final responseText = await api_services.isArt(lastWords);
            print("API response: $responseText");
            if (responseText.contains("https://")) {
              generatedImageUrl = responseText;
              generatedContent = null;
            } else {
              generatedContent = responseText;
              generatedImageUrl = null;
              await speak(responseText);
            }
            setState(() {});
            await stopListening();
          } else {
            await initSpeechtoText();
          }
        },
        backgroundColor: speechToText.isListening ? Colors.red : Pallete.accentColor,
        child: Icon(speechToText.isListening ? Icons.stop : Icons.mic),
      ),
      // Create a chatbox here
      
    );
  }
}
