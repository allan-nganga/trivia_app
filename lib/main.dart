import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(TriviaApp());
}

class TriviaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trivia App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        QuizScreen.routeName: (context) => QuizScreen(),
        ScoreScreen.routeName: (context) => ScoreScreen(),
      },
    );
  }
}

// HomeScreen.dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trivia Home'),
      ),
      body: Center(
        child: ElevatedButton(
          child: Text('Start Quiz'),
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
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    final url = Uri.parse('https://opentdb.com/api.php?amount=5&category=9&type=multiple');
    final response = await http.get(url);
    final data = json.decode(response.body);

    setState(() {
      _questions = data['results'];
      _isLoading = false;
    });
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
        title: Text('Trivia Quiz'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    _questions[_currentQuestionIndex]['question'] as String,
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                ...(_questions[_currentQuestionIndex]['incorrect_answers'] as List<dynamic>)
                    .map((answer) {
                  return ElevatedButton(
                    child: Text(answer),
                    onPressed: () => _answerQuestion(answer),
                  );
                }).toList(),
                ElevatedButton(
                  child: Text(_questions[_currentQuestionIndex]['correct_answer']),
                  onPressed: () => _answerQuestion(_questions[_currentQuestionIndex]['correct_answer']),
                )
              ],
            ),
    );
  }
}

// ScoreScreen.dart
class ScoreScreen extends StatelessWidget {
  static const routeName = '/score';

  @override
  Widget build(BuildContext context) {
    final int score = ModalRoute.of(context)!.settings.arguments as int;

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Score'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Your Score: $score',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              child: Text('Restart Quiz'),
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