import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jarvis/secreats.dart';

class API_SERVICES {
  final List<Map<String, String>> messages = [];

  /// Main entry point for processing the user's prompt.
  /// Depending on `selectedModel`, it calls the appropriate method.
  Future<String> processPrompt(String prompt, String selectedModel) async {
    if (selectedModel == "Gemini Flash 2.0 Pro") {
      return await geminiAPI(prompt);
    } else if (selectedModel == "DeepSeek V3") {
      return await deepSeekAPI(prompt);
    } else {
      // Default to deepSeekAPI if model is not recognized.
      return await deepSeekAPI(prompt);
    }
  }

  /// Helper method to remove or replace unwanted characters from the response.
  /// Adjust the regex or replacement logic to your specific needs.
  String cleanResponse(String raw) {
    // Example: remove #, &, *, multiple spaces, etc.
    // You can add or remove characters from the set below.
    final cleaned = raw
        .replaceAll(RegExp(r'[#&*]'), '')    // Remove #, &, *
        .replaceAll(RegExp(r'\s+'), ' ')     // Convert multiple spaces to single space
        .trim();
    return cleaned;
  }

  Future<String> deepSeekAPI(String prompt) async {
    messages.add({"role": "user", "content": prompt});
    try {
      final response = await http.post(
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $DeepSeekAPIKey",
        },
        body: jsonEncode({
          "model": "deepseek/deepseek-chat-v3-0324:free",
          "messages": messages,
        }),
      );

      print("deepSeekAPI response: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse != null &&
            jsonResponse["choices"] != null &&
            jsonResponse["choices"] is List &&
            jsonResponse["choices"].isNotEmpty &&
            jsonResponse["choices"][0]["message"] != null &&
            jsonResponse["choices"][0]["message"]["content"] != null) {
          String responseString =
              jsonResponse["choices"][0]["message"]["content"].trim();

          // Clean the response before returning
          responseString = cleanResponse(responseString);

          messages.add({"role": "assistant", "content": responseString});
          return responseString;
        }
        return "Error: Unexpected response structure from DeepSeek API";
      }
      return "Error: Invalid response from DeepSeek API: ${response.statusCode}";
    } catch (e) {
      print("deepSeekAPI error: $e");
      return "Error: $e";
    }
  }

  Future<String> geminiAPI(String prompt) async {
    try {
      final url = Uri.parse(
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp-image-generation:generateContent?key=$GEMINI_API_KEY");

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ],
        "generationConfig": {"responseModalities": ["Text", "Image"]}
      });

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      print("Gemini API response: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse != null &&
            jsonResponse["contents"] != null &&
            jsonResponse["contents"] is List &&
            jsonResponse["contents"].isNotEmpty) {
          final content = jsonResponse["contents"][0];
          if (content["data"] != null) {
            // For images, you may not need cleaning, but let's do it anyway in case there's text.
            String imageData = cleanResponse(content["data"]);
            messages.add({"role": "assistant", "content": imageData});
            return imageData;
          }
        }
        return "Error: No image data received from Gemini API";
      }
      return "Error: Invalid response from Gemini API: ${response.statusCode}";
    } catch (e) {
      print("GeminiAPI error: $e");
      return "Error: $e";
    }
  }

  Future<String> geminiProAPI(String prompt) async {
    try {
      final url = Uri.parse("https://openrouter.ai/api/v1/chat/completions");
      final body = jsonEncode({
        "model": "google/gemini-2.5-pro-exp-03-25:free",
        "messages": [
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text": prompt
              }
            ]
          }
        ]
      });

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $GEMINI_API_KEY"
        },
        body: body,
      );

      print("GeminiPro API response: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print("Full GeminiPro JSON response: $jsonResponse");
        if (jsonResponse != null &&
            jsonResponse["choices"] != null &&
            jsonResponse["choices"] is List &&
            jsonResponse["choices"].isNotEmpty &&
            jsonResponse["choices"][0]["message"] != null &&
            jsonResponse["choices"][0]["message"]["content"] != null) {
          String responseString =
              jsonResponse["choices"][0]["message"]["content"].toString();

          // Clean the response
          responseString = cleanResponse(responseString);

          return responseString;
        }
        return "Error: Unexpected response structure from GeminiPro API";
      }
      return "Error: Invalid response from GeminiPro API: ${response.statusCode}";
    } catch (e) {
      print("GeminiProAPI error: $e");
      return "Error: $e";
    }
  }
}
