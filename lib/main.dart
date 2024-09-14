// main.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // To detect SocketException
import 'package:connectivity_plus/connectivity_plus.dart'; // For network connectivity check

void main() {
  runApp(const TriviaApp());
}

class TriviaApp extends StatelessWidget {
  const TriviaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trivia App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          color: Colors.lightBlueAccent
        )
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        QuizScreen.routeName: (context) => const QuizScreen(),
        ScoreScreen.routeName: (context) => const ScoreScreen(),
      },
    );
  }
}

// HomeScreen.dart
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trivia Home'),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Start Quiz'),
          onPressed: () {
            Navigator.pushNamed(context, QuizScreen.routeName);
          },
        ),
      ),
    );
  }
}

// QuizScreen.dart
class QuizScreen extends StatefulWidget {
  static const routeName = '/quiz';

  const QuizScreen({super.key});
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    // First, check for internet connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _hasError = true;
        _errorMessage = 'No internet connection. Please check your network settings.';
        _isLoading = false;
      });
      return;
    }

    try {
      final url = Uri.parse('https://opentdb.com/api.php?amount=5&category=9&type=multiple');
      
      // Set a 10-second timeout for the request
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _questions = data['results'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Server error: ${response.statusCode}. Please try again later.';
          _isLoading = false;
        });
      }
    } on SocketException {
      // No Internet connection
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to connect to the server. Please check your internet connection.';
        _isLoading = false;
      });
    } on TimeoutException {
      // Request timeout
      setState(() {
        _hasError = true;
        _errorMessage = 'Request timed out. Please try again later.';
        _isLoading = false;
      });
    } catch (error) {
      // Any other errors
      setState(() {
        _hasError = true;
        _errorMessage = 'An unexpected error occurred: $error. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _answerQuestion(String selectedAnswer) {
    if (selectedAnswer == _questions[_currentQuestionIndex]['correct_answer']) {
      setState(() {
        _score++;
      });
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      Navigator.pushReplacementNamed(
        context,
        ScoreScreen.routeName,
        arguments: _score,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trivia Quiz'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _fetchQuestions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        _questions[_currentQuestionIndex]['question'] as String,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    ...(_questions[_currentQuestionIndex]['incorrect_answers'] as List<dynamic>)
                        .map((answer) {
                      return ElevatedButton(
                        child: Text(answer),
                        onPressed: () => _answerQuestion(answer),
                      );
                    }),
                    ElevatedButton(
                      child: Text(_questions[_currentQuestionIndex]['correct_answer']),
                      onPressed: () => _answerQuestion(_questions[_currentQuestionIndex]['correct_answer']),
                    ),
                  ],
                ),
    );
  }
}

// ScoreScreen.dart
class ScoreScreen extends StatelessWidget {
  static const routeName = '/score';

  const ScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final int score = ModalRoute.of(context)!.settings.arguments as int;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Score'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Your Score: $score',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              child: const Text('Restart Quiz'),
              onPressed: () {
                Navigator.pushReplacementNamed(context, QuizScreen.routeName);
              },
            ),
          ],
        ),
      ),
    );
  }
}