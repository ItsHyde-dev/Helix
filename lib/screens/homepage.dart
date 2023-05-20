import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'noteslist.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
          theme: ThemeData(
              canvasColor: Colors.transparent,
              scaffoldBackgroundColor: Colors.transparent,
              textTheme: const TextTheme(
                  titleMedium: TextStyle(color: Colors.white, fontSize: 20),
                  bodySmall: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontStyle: FontStyle.italic),
                  bodyLarge: TextStyle(
                      color: Colors.white,
                      fontSize: 35,
                      fontFamily: 'Fasthand'),
                  bodyMedium: TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              inputDecorationTheme: const InputDecorationTheme(
                  outlineBorder: BorderSide.none,
                  hintStyle: TextStyle(color: Colors.white, fontSize: 20),
                  labelStyle: TextStyle(color: Colors.white, fontSize: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  )),
              iconTheme: const IconThemeData(color: Colors.white)),
          home: const Home()),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      return Container(
          decoration: const BoxDecoration(
              // gradient: LinearGradient(
              //     begin: Alignment.topCenter,
              //     end: Alignment.bottomCenter,
              //     colors: [Color.fromARGB(255, 53, 53, 53), Colors.black])
              ),
          child: const Scaffold(body: NotesList()));
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));

      return const CircularProgressIndicator.adaptive();
    }
  }
}
