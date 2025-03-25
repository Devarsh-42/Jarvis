import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jarvis/secreats.dart';
import 'package:fal_client/fal_client.dart';

class API_SERVICES {
  final List<Map<String, String>> messages = [];
  final fal = FalClient.withCredentials('$GEMINI_API_KEY');

  Future<String> isArt(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $DeepSeekAPIKey",
        },
        body: jsonEncode({
          "model": "deepseek/deepseek-chat-v3-0324:free",
          "messages": [
            {
              "role": "user",
              "content":
                  "Does this prompt want to generate AI Picture, art, Image or anything similar? $prompt if yes then simply reply with 'yes' or 'no' if not."
            },
          ]
        }),
      );

      print("isArt response: ${response.body}");

      if (response.statusCode == 200) {
        String responseString = jsonDecode(response.body)['choices'][0]['message']['content']
                .trim()
                .toLowerCase();

        print("isArt model replied: $responseString");

        // If the response starts with "yes", generate image; if "no" or any other response, generate text.
        if (responseString.startsWith("yes")) {
          return await DallEAPI(prompt);
        } else {
          return await ChatGPTAPI(prompt);
        }
      }
      return "Error: Invalid response from API";
    } catch (e) {
      print("isArt error: $e");
      return "Error: $e";
    }
  }

  Future<String> ChatGPTAPI(String prompt) async {
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

      print("ChatGPTAPI response: ${response.body}");

      if (response.statusCode == 200) {
        String responseString = jsonDecode(response.body)['choices'][0]['message']['content']
                .trim();
        messages.add({"role": "assistant", "content": responseString});
        return responseString;
      }
      return "Error: Invalid response from DeepSeek";
    } catch (e) {
      print("ChatGPTAPI error: $e");
      return "Error: $e";
    }
  }

  Future<String> DallEAPI(String prompt) async {
    try {
      final job = await fal.queue.submit(
        "fal-ai/flux/dev",
        input: {
          "prompt": prompt,
          "seed": DateTime.now().millisecondsSinceEpoch,
          "image_size": "landscape_4_3",
          "num_images": 1
        },
      );
      print("Submitted job with requestId: ${job.requestId}");
      
      await Future.delayed(Duration(seconds: 2));
      
      final output = await fal.queue.result(
        "fal-ai/flux/dev",
        requestId: job.requestId,
      );
      
      print("Retrieved job result: ${output.data}");
      
      if (output.data != null && output.data is List && output.data.isNotEmpty) {
        String imageUrl = output.data[0];
        messages.add({"role": "assistant", "content": imageUrl});
        return imageUrl;
      }
      return "Error: No image data received";
    } catch (e) {
      print("DallEAPI error: $e");
      return "Error: $e";
    }
  }
}
