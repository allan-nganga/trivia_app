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
        appBarTheme: const AppBarTheme(color: Colors.lightBlueAccent),
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
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List _categories = [];
  bool _isLoadingCategories = true;
  String _categoryErrorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final url = Uri.parse('https://opentdb.com/api_category.php');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _categories = data['trivia_categories'];
          _isLoadingCategories = false;
        });
      } else {
        setState(() {
          _categoryErrorMessage = 'Failed to load categories';
          _isLoadingCategories = false;
        });
      }
    } catch (error) {
      setState(() {
        _categoryErrorMessage = 'An error occurred: $error';
        _isLoadingCategories = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Trivia Category'),
      ),
      body: Center(
        child: _isLoadingCategories
            ? const CircularProgressIndicator()
            : _categoryErrorMessage.isNotEmpty
                ? Text(_categoryErrorMessage)
                : ListView.builder(
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                            bottom: 12.0), // Spac3 between cards
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(15.0), // Rounded corners
                          ),
                          elevation: 4.0, // shadow card effect
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.all(16.0), // Internal padding
                            leading: Icon(
                              Icons.category,
                              color:
                                  Colors.blueAccent, // Icon for each category
                              size: 32,
                            ),
                            title: Text(
                              category['name'],
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            tileColor: Colors.blue[50],
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                QuizScreen.routeName,
                                arguments: category['id'].toString(),
                              );
                            },
                          ),
                        ),
                      );
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
  List<String> _userAnswers = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String? _categoryId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_categoryId == null) {
      _categoryId = ModalRoute.of(context)!.settings.arguments as String;
      _fetchQuestions();
    }
  }

  Future<void> _fetchQuestions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

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
      final url = Uri.parse('https://opentdb.com/api.php?amount=5&category=$_categoryId&type=multiple');
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
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to connect to the server. Please check your internet connection.';
        _isLoading = false;
      });
    } on TimeoutException {
      setState(() {
        _hasError = true;
        _errorMessage = 'Request timed out. Please try again later.';
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _hasError = true;
        _errorMessage = 'An unexpected error occurred: $error. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _answerQuestion(String selectedAnswer) {
    _userAnswers.add(selectedAnswer);

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
        arguments: {
          'score': _score,
          'questions': _questions,
          'userAnswers': _userAnswers,
        },
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
                      Text(
                        _errorMessage,
                        style: const TextStyle(fontSize: 18, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _fetchQuestions, // Retry fetching questions
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
    // Get the score, questions, and userAnswers passed from QuizScreen
    final Map<String, Object> args = ModalRoute.of(context)!.settings.arguments as Map<String, Object>;
    final int score = args['score'] as int;
    final List questions = args['questions'] as List;
    final List<String> userAnswers = args['userAnswers'] as List<String>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Score'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Text(
              'Your Score: $score',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];
                  final correctAnswer = question['correct_answer'];
                  final userAnswer = userAnswers[index];
                  final answers = List<String>.from(question['incorrect_answers']);
                  answers.add(correctAnswer);
                  answers.shuffle(); // Shuffle answers for random order

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question['question'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        // Display the answers with correct/incorrect highlights
                        Column(
                          children: answers.map((answer) {
                            Color answerColor;
                            if (answer == correctAnswer) {
                              answerColor = Colors.green; // Correct answer in green
                            } else if (answer == userAnswer) {
                              answerColor = Colors.red; // Incorrect answer in red
                            } else {
                              answerColor = Colors.black; // Default color for unselected answers
                            }
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(
                                answer,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: answerColor,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              child: const Text('Go to Home'),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}