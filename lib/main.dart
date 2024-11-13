import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flip_card/flip_card.dart';

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

  void _confirmDeleteFlashcard(Flashcard flashcard) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Flashcard'),
          content: Text('Are you sure you want to delete this flashcard?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog, no deletion
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  flashcards.remove(flashcard); // Delete the flashcard
                });
                _saveFlashcards();
                Navigator.of(context).pop(); // Close dialog after deletion
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
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
      top: 20.0 * index.toDouble(),
      child: Dismissible(
        key: UniqueKey(),
        direction: DismissDirection.horizontal,
        confirmDismiss: (DismissDirection direction) async {
          // Show confirmation dialog and return a boolean for dismiss
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Delete Flashcard'),
                content:
                    Text('Are you sure you want to delete this flashcard?'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false); // Cancel delete
                    },
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true); // Confirm delete
                    },
                    child: Text('Delete'),
                  ),
                ],
              );
            },
          );
        },
        onDismissed: (direction) {
          _deleteFlashcard(flashcard); // Perform deletion
        },
        child: FlipCard(
          front: _buildCardSide(flashcard, index, true),
          back: _buildCardSide(flashcard, index, false),
          direction: FlipDirection.HORIZONTAL,
        ),
      ),
    );
  }

  void _deleteFlashcard(Flashcard flashcard) {
    setState(() {
      flashcards.remove(flashcard);
    });
    _saveFlashcards();
  }

  Widget _buildCardSide(Flashcard flashcard, int index, bool isFront) {
    return Container(
      margin: EdgeInsets.all(16),
      height: 300,
      width: 350,
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
                    fontSize: 35,
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
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 28,
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
