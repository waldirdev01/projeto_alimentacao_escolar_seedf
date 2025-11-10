import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'database/firestore_helper.dart';
import 'firebase_options.dart';
import 'screens/profile_selection_screen.dart';
import 'theme/app_theme.dart';

Future<void> _initializeFirebase() async {
  debugPrint('[FirebaseInit] Iniciando processo de inicialização.');

  try {
    debugPrint('[FirebaseInit] Tentando inicializar Firebase.initializeApp...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[FirebaseInit] Firebase.initializeApp concluído com sucesso.');
  } on FirebaseException catch (e, stack) {
    if (e.code == 'duplicate-app') {
      debugPrint(
        '[FirebaseInit] App padrão já existia. Recuperando instância existente.',
      );
      final existingApp = Firebase.app();
      debugPrint('[FirebaseInit] App recuperado: ${existingApp.name}.');
    } else {
      debugPrint(
        '[FirebaseInit] Erro ao inicializar Firebase: ${e.code} -> ${e.message}',
      );
      debugPrint('[FirebaseInit] Stacktrace: $stack');
      rethrow;
    }
  } catch (e, stack) {
    debugPrint('[FirebaseInit] Erro inesperado durante inicialização: $e');
    debugPrint('[FirebaseInit] Stacktrace: $stack');
    rethrow;
  }

  try {
    debugPrint('[FirebaseInit] Inicializando dados padrões do Firestore...');
    await FirestoreHelper().initializeDefaultData();
    debugPrint('[FirebaseInit] Dados padrões do Firestore inicializados.');
  } catch (e, stack) {
    if (e is FirebaseException && e.code == 'permission-denied') {
      debugPrint(
        '[FirebaseInit] Permissão negada ao inicializar dados padrões. '
        'Verifique regras do Firestore ou ignore se já configurado.',
      );
    } else {
      debugPrint(
        '[FirebaseInit] Erro ao inicializar dados padrões do Firestore: $e',
      );
      debugPrint('[FirebaseInit] Stacktrace: $stack');
      rethrow;
    }
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[Main] WidgetsFlutterBinding inicializado.');
  final initialization = _initializeFirebase();
  debugPrint('[Main] Future de inicialização criado.');

  runApp(MerendaApp(initialization: initialization));
}

class MerendaApp extends StatelessWidget {
  final Future<void> initialization;

  const MerendaApp({super.key, required this.initialization});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Alimentação Escolar - DF',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<void>(
        future: initialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return const ProfileSelectionScreen();
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Não foi possível inicializar os dados.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
