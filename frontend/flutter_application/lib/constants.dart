import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Replace this with your actual Render URL
  static const String apiUrl = 'https://smart-pdf-backend-rj6v.onrender.com/api/v1';
  
  // Loaded from .env file
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  
  // Loaded from .env file
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
}
