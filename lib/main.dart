import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flip_card/flip_card.dart'; // Import the flip_card package

import 'add_edit_flashcard_screen.dart';

void main() {
  runApp(FlashcardApp());
}

class Flashcard {
  String question;
  String answer;

  Flashcard({required this.question, required this.answer});

  Map<String, dynamic> toJson() => {
        'question': question,
        'answer': answer,
      };

  static Flashcard fromJson(Map<String, dynamic> json) =>
      Flashcard(question: json['question'], answer: json['answer']);
}

class FlashcardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flashcard App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FlashcardListScreen(),
    );
  }
}

class FlashcardListScreen extends StatefulWidget {
  @override
  _FlashcardListScreenState createState() => _FlashcardListScreenState();
}

class _FlashcardListScreenState extends State<FlashcardListScreen> {
  List<Flashcard> flashcards = [];
  final List<Color> cardColors = [
    Colors.lightBlueAccent,
    Colors.lightGreenAccent,
    Colors.pinkAccent,
    Colors.amberAccent,
    Colors.deepPurpleAccent,
    Colors.cyanAccent,
    Colors.orangeAccent,
  ];

  @override
  void initState() {
    super.initState();
    _initializeFlashcards();
  }

  Future<void> _initializeFlashcards() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> flashcardList = prefs.getStringList('flashcards') ?? [];

    if (flashcardList.isEmpty) {
      flashcards = [
        Flashcard(
            question: 'What is Flutter?', answer: 'A UI toolkit by Google.'),
        Flashcard(question: 'What language does Flutter use?', answer: 'Dart.'),
        Flashcard(
            question: 'What is a widget in Flutter?',
            answer: 'A building block of UI.'),
      ];
      _saveFlashcards();
    } else {
      flashcards = flashcardList
          .map((item) => Flashcard.fromJson(json.decode(item)))
          .toList();
    }

    setState(() {});
  }

  Future<void> _saveFlashcards() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> flashcardList =
        flashcards.map((fc) => json.encode(fc.toJson())).toList();
    prefs.setStringList('flashcards', flashcardList);
  }

  void _addOrEditFlashcard([Flashcard? flashcard]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddEditFlashcardScreen(
                flashcard: flashcard,
              )),
    );

    if (result != null) {
      setState(() {
        if (flashcard != null) {
          flashcards[flashcards.indexOf(flashcard)] = result;
        } else {
          flashcards.add(result);
        }
      });
      _saveFlashcards();
    }
  }

  void _deleteFlashcard(Flashcard flashcard) {
    setState(() {
      flashcards.remove(flashcard);
    });
    _saveFlashcards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flashcards'),
      ),
      body: Center(
        child: flashcards.isEmpty
            ? Text('No flashcards available')
            : Center(
                // Center the stack of cards in the middle of the screen
                child: Stack(
                  alignment: Alignment.center,
                  children:
                      flashcards.reversed.toList().asMap().entries.map((entry) {
                    int index = entry.key;
                    Flashcard flashcard = entry.value;
                    return _buildDeckCard(flashcard, index);
                  }).toList(),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditFlashcard(),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildDeckCard(Flashcard flashcard, int index) {
    return Positioned(
      top: 20.0 * index.toDouble(), // Offset cards slightly based on index
      child: Dismissible(
        key: UniqueKey(),
        onDismissed: (direction) {
          _deleteFlashcard(flashcard);
        },
        child: FlipCard(
          front:
              _buildCardSide(flashcard, index, true), // Front side (question)
          back: _buildCardSide(flashcard, index, false), // Back side (answer)
          direction: FlipDirection
              .HORIZONTAL, // You can set this to either HORIZONTAL or VERTICAL
        ),
      ),
    );
  }

  Widget _buildCardSide(Flashcard flashcard, int index, bool isFront) {
    return Container(
      margin: EdgeInsets.all(16),
      height: 300, // Fixed height for each card
      width: 350, // Fixed width for each card
      decoration: BoxDecoration(
        color: cardColors[index % cardColors.length],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isFront ? flashcard.question : flashcard.answer,
                  style: TextStyle(
                    fontSize: 35, // Increased font size
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  isFront ? 'Tap to flip' : 'Tap to flip back',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
          // Use Align widget to explicitly position the icon at the bottom-right corner
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 28, // Increased the size of the edit icon
                ),
                onPressed: () => _addOrEditFlashcard(flashcard),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
