import 'package:http/http.dart' as http;

// 1. RUN THIS FILE BY OPENING TERMINAL AND TYPING:
// flutter run lib/test_telegram.dart  <-- (This won't work for standalone files easily in Flutter)
// EASIER WAY: Modify your main.dart temporarily OR just look at the debug console below.

void main() async {
  // --- CONFIG ---
  const String botToken = '8595213600:AAGCpThJlKgvkZWWQ4TyN5TnMTEftjJckKg';
  
  // TRY BOTH ID VERSIONS HERE TO SEE WHICH ONE WORKS
  // Option A (Supergroup): '-1005261049054'
  // Option B (Basic Group): '-5261049054'
  const String chatId = '-1005261049054'; 

  print("Attempting to send message to ID: $chatId...");

  final url = Uri.parse('https://api.telegram.org/bot$botToken/sendMessage');
  
  try {
    final response = await http.post(url, body: {
      'chat_id': chatId,
      'text': '🔥 TEST MESSAGE from VNB Admin Debugger',
    });

    print('Response Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    
    if (response.statusCode == 200) {
      print("✅ SUCCESS! The ID $chatId is correct.");
    } else {
      print("❌ FAILED. Read the 'description' in the Response Body above to see why.");
    }
  } catch (e) {
    print("Error: $e");
  }
}