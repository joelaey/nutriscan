import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/health_input_screen.dart';
import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/processing_screen.dart';
import 'screens/result_screen.dart';
import 'screens/history_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.backgroundColor,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const NutriScanApp());
}

class NutriScanApp extends StatelessWidget {
  const NutriScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriScan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Handle routes with arguments
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (context) => const SplashScreen(),
            );
          case '/login':
            return MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            );
          case '/health-input':
            return MaterialPageRoute(
              builder: (context) => const HealthInputScreen(),
            );
          case '/home':
            return MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            );
          case '/scan':
            return MaterialPageRoute(
              builder: (context) => const ScanScreen(),
            );
          case '/processing':
            // Accept Map argument with image and productName
            final args = settings.arguments;
            File? imageFile;
            String? productName;
            
            if (args is Map<String, dynamic>) {
              imageFile = args['image'] as File?;
              productName = args['productName'] as String?;
            } else if (args is File) {
              // Backwards compatibility - accept File directly
              imageFile = args;
            }
            
            return MaterialPageRoute(
              builder: (context) => ProcessingScreen(
                imageFile: imageFile,
                productName: productName,
              ),
            );
          case '/result':
            return MaterialPageRoute(
              builder: (context) => const ResultScreen(),
              settings: settings, // Pass arguments through
            );
          case '/history':
            return MaterialPageRoute(
              builder: (context) => const HistoryScreen(),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => const SplashScreen(),
            );
        }
      },
    );
  }
}
