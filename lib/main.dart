import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'database/firestore_helper.dart';
import 'firebase_options.dart';
import 'screens/profile_selection_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializar dados padrão no Firestore
  await FirestoreHelper().initializeDefaultData();

  runApp(const MerendaApp());
}

class MerendaApp extends StatelessWidget {
  const MerendaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Alimentação Escolar - DF',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const ProfileSelectionScreen(),
    );
  }
}
