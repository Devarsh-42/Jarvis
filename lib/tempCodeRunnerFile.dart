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

  /// This has to happen only once per app
  Future<void> initSpeechtoText() async {
    await speechToText.initialize();
    setState(() {});
  }

  Future<void> initTextToSpeech() async{


  }
  /// Each time to start a speech recognition session
  Future<void> startListening() async {
    await speechToText.listen(onResult: onSpeechResult);
    setState(() {});
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  Future<void> stopListening() async {
    await speechToText.stop();
    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      lastWords = result.recognizedWords;
    });
  }

  Future<void> speak(String text) async {
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    super.dispose();
    speechToText.stop();
    flutterTts.stop();
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
              SizedBox(height: 20),
              //Voice Assistant Icon
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
                        image: DecorationImage(
                            image: AssetImage(
                                "assets/images/virtualAssistant.png")),
                      ),
                    ),
                  )
                ],
              ),
              //Chat Bubble
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                margin:
                    EdgeInsets.only(top: 30, bottom: 10, left: 30, right: 10),
                decoration: BoxDecoration(
                  color: Pallete.cardColor,
                  border: Border.all(color: Pallete.borderColor),
                  borderRadius: BorderRadius.circular(20)
                      .copyWith(topLeft: Radius.circular(0)),
                ),
                child: Text(
                  generatedContent == null ? "Hello, I'm Jarvis. How can I help you today?" : generatedContent!,
                  style: TextStyle(fontSize: generatedContent == null ? 20 : 18, fontFamily: "Michroma"),
                ),
              ),
              Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.only(top: 5, left: 5),
                alignment: Alignment.centerLeft,
                child: Text(
                  "Here are Few Key Features",
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: "Michroma",
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 49, 140, 193)),
                ),
              ),
              Column(
                children: [
                  Featurebox(
                      color: Pallete.secondSuggestionBoxColor,
                      title: "Jarvis",
                      description:
                          "Jarvis is a virtual & voice assistant that can help you with your daily tasks, So that you can become Tony Stark of your life."),
                  Featurebox(
                      color: Pallete.firstSuggestionBoxColor,
                      title: "ChatGPT",
                      description:
                          "ChatGPT 3 is an LLM that has been trained to generate human-like responses to given prompts."),
                  Featurebox(
                      color: Pallete.thirdSuggestionBoxColor,
                      title: "Dall-E",
                      description:
                          "DALL·E is an Text-to-Image Transformer that generates images from textual descriptions."),
                  SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            if (await speechToText.hasPermission && !speechToText.isListening) {
              print(lastWords);
              await startListening();
            } else if (speechToText.isListening) {
              final speech = await api_services.isArt(lastWords);
              if(speech.contains("https://")) {
                generatedImageUrl = speech;
                generatedContent = null;
                setState(() {
                  
                });
              } else {
                generatedContent = speech;
                generatedImageUrl = null;
                await speak(speech);
                setState(() {
                  
                });
              }
              await stopListening();
            } else {
              initSpeechtoText();
            }
          },
          backgroundColor:
              speechToText.isListening ? Colors.red : Pallete.accentColor,
          child: Icon(speechToText.isListening ? Icons.stop : Icons.mic),
        ));
  }
}
