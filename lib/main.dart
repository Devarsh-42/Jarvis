import 'package:flutter/material.dart';
import 'package:jarvis/home_page.dart';
import 'package:jarvis/pallet.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jarvis Voice Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Pallete.backgroundColor,
        cardColor: Pallete.cardColor,
        colorScheme: ColorScheme.dark(
          primary: Pallete.accentColor,
          onPrimary: Pallete.whiteColor,
          secondary: Pallete.assistantCircleColor,
          surface: Pallete.cardColor,
          background: Pallete.backgroundColor,
          onBackground: Pallete.mainFontColor,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Pallete.mainFontColor),
          bodyMedium: TextStyle(color: Pallete.mainFontColor),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Pallete.backgroundColor,
          elevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}