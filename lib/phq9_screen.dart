import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'config.dart';
import 'crisis_check.dart';
import 'emergency_screen.dart';
import 'history_screen.dart';
import 'resources_screen.dart';
import 'welcome_screen.dart';

// Wording follows the standard PHQ-9 and GAD-7. Your guidance counselor
// should confirm the exact text (and any translation) before real use.
const List<String> phq9Questions = [
  'Little interest or pleasure in doing things',
  'Feeling down, depressed, or hopeless',
  'Trouble falling or staying asleep, or sleeping too much',
  'Feeling tired or having little energy',
  'Poor appetite or overeating',
  'Feeling bad about yourself, or that you are a failure or have let yourself or your family down',
  'Trouble concentrating on things, such as reading the newspaper or watching television',
  'Moving or speaking so slowly that other people could have noticed, or the opposite: being so fidgety or restless that you have been moving around a lot more than usual',
  'Thoughts that you would be better off dead, or of hurting yourself in some way',
];

const List<String> gad7Questions = [
  'Feeling nervous, anxious, or on edge',
  'Not being able to stop or control worrying',
  'Worrying too much about different things',
  'Trouble relaxing',
  'Being so restless that it is hard to sit still',
  'Becoming easily annoyed or irritable',
  'Feeling afraid, as if something awful might happen',
];

const List<String> answerLabels = [
  'Not at all',
  'Several days',
  'More than half the days',
  'Nearly every day',
];

// This message must be reviewed by your guidance counselor before any
// real student uses the app.
const String crisisText =
    "What you shared tells me you may be going through something very painful. You don't have to face it alone. Please reach out to someone you trust or a mental health professional right now. If you are in immediate danger, contact your local emergency services.";

class ChatMessage {
  final String text;
  final bool fromUser;

  const ChatMessage(this.text, this.fromUser);
}

class Phq9Screen extends StatefulWidget {
  const Phq9Screen({super.key});

  @override
  State<Phq9Screen> createState() => _Phq9ScreenState();
}

class _Phq9ScreenState extends State<Phq9Screen> {
  final List<ChatMessage> _messages = [];
  final List<int> _answers = [];
  final ScrollController _scroll = ScrollController();
  final TextEditingController _controller = TextEditingController();
  String? _test; // null until the user picks 'phq9' or 'gad7'
  int _current = 0;
  bool _finished = false;

  List<String> get _questions =>
      _test == 'gad7' ? gad7Questions : phq9Questions;

  int get _maxScore => _questions.length * 3;

  @override
  void initState() {
    super.initState();
    _messages.add(const ChatMessage(
      "Hi, I'm Kalinaw. You can type how you're feeling anytime, or take a short check. These are screenings, not a diagnosis.",
      false,
    ));
    _messages.add(const ChatMessage(
      'Which check would you like to take?',
      false,
    ));
  }

  @override
  void dispose() {
    _scroll.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _openEmergency() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmergencyScreen()),
    );
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
  }

  void _openResources() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ResourcesScreen()),
    );
  }

  // Logs out (if logged in) and returns to the welcome screen.
  void _goToStart() {
    AuthService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (route) => false,
    );
  }

  void _chooseTest(String test) {
    setState(() {
      _test = test;
      _messages.add(ChatMessage(
        test == 'phq9' ? 'Mood check (PHQ-9)' : 'Anxiety check (GAD-7)',
        true,
      ));
      _messages.add(const ChatMessage(
        'Over the last 2 weeks, how often have you been bothered by:',
        false,
      ));
      _messages.add(ChatMessage(_questions[0], false));
    });
    _scrollToBottom();
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text, true));
    });
    _scrollToBottom();

    // Step 1: check on the phone first. This works with no internet.
    if (messageHasWarning(text)) {
      setState(() {
        _messages.add(const ChatMessage(crisisText, false));
      });
      _scrollToBottom();
      _openEmergency();
      return;
    }

    // Step 2: ask the backend, which may know more phrases later.
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/chat/check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': text}),
      );

      if (response.statusCode != 200) {
        throw Exception('Unexpected response: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final bool crisis = data['crisis'] == true;

      if (!mounted) return;

      setState(() {
        if (crisis) {
          _messages.add(const ChatMessage(crisisText, false));
        } else if (_finished) {
          _messages.add(const ChatMessage(
            "Thank you for sharing that. If things feel heavy, it could help to talk with a guidance counselor.",
            false,
          ));
        } else {
          _messages.add(const ChatMessage(
            "Thank you for telling me. I'm listening. Whenever you're ready, you can continue with the check below.",
            false,
          ));
        }
      });

      if (crisis) {
        _openEmergency();
      }
    } catch (error) {
      print('Chat check error: $error');
      if (!mounted) return;

      setState(() {
        _messages.add(const ChatMessage(
          "I couldn't check your message right now. If you are in danger or need urgent help, please tap Get help at the top, or contact someone you trust or your local emergency services.",
          false,
        ));
      });
    }

    _scrollToBottom();
  }

  void _answer(int value) {
    setState(() {
      _messages.add(ChatMessage(answerLabels[value], true));
      _answers.add(value);
      _current++;

      if (_current < _questions.length) {
        _messages.add(ChatMessage(_questions[_current], false));
      } else {
        _finished = true;
      }
    });
    _scrollToBottom();

    if (_finished) {
      _submit();
    }
  }

  Future<void> _submit() async {
    setState(() {
      _messages.add(const ChatMessage('Thank you. Calculating your result...', false));
    });

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/screen/$_test'),
        headers: AuthService.headers(),
        body: jsonEncode({'answers': _answers}),
      );

      if (response.statusCode != 200) {
        throw Exception('Unexpected response: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final int total = data['total'];
      final String level = data['level'];
      final bool crisis = data['crisis'] == true;
      final bool saved = data['saved'] == true;

      if (!mounted) return;

      setState(() {
        if (crisis) {
          _messages.add(const ChatMessage(crisisText, false));
        }

        _messages.add(ChatMessage(
          'Your total score is $total out of $_maxScore. Level: $level.',
          false,
        ));

        if (total >= 10) {
          _messages.add(const ChatMessage(
            'A score at this level suggests it could help to talk with a guidance counselor or mental health professional. This screening is not a diagnosis.',
            false,
          ));
        } else {
          _messages.add(const ChatMessage(
            'Your answers suggest few symptoms right now. Keep taking care of yourself, and check in again anytime. This screening is not a diagnosis.',
            false,
          ));
        }

        if (saved) {
          _messages.add(const ChatMessage(
            'Your result was saved to your history. You can delete it anytime.',
            false,
          ));
        } else if (AuthService.loggedIn) {
          _messages.add(const ChatMessage(
            "I couldn't save this result. Your login may have expired. Please log in again.",
            false,
          ));
        } else {
          _messages.add(const ChatMessage(
            'You are in guest mode, so this result was not saved.',
            false,
          ));
        }
      });

      if (crisis) {
        _openEmergency();
      }
    } catch (error) {
      print('Submit error: $error');
      if (!mounted) return;

      setState(() {
        _messages.add(const ChatMessage(
          "Sorry, I couldn't reach the server to calculate your result. Please try again later.",
          false,
        ));
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _bubble(ChatMessage message) {
    final colors = Theme.of(context).colorScheme;

    return Align(
      alignment:
          message.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.fromUser
              ? colors.primary
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.fromUser ? colors.onPrimary : colors.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _choiceButtons() {
    if (_finished) return const SizedBox.shrink();

    final List<Widget> buttons;

    if (_test == null) {
      buttons = [
        ElevatedButton(
          onPressed: () => _chooseTest('phq9'),
          child: const Text('Mood check (PHQ-9)'),
        ),
        ElevatedButton(
          onPressed: () => _chooseTest('gad7'),
          child: const Text('Anxiety check (GAD-7)'),
        ),
      ];
    } else {
      buttons = [
        for (int i = 0; i < answerLabels.length; i++)
          ElevatedButton(
            onPressed: () => _answer(i),
            child: Text(answerLabels[i]),
          ),
      ];
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(spacing: 8, runSpacing: 8, children: buttons),
    );
  }

  Widget _inputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendText(),
              decoration: InputDecoration(
                hintText: 'Type how you feel...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendText,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalinaw'),
        actions: [
          TextButton.icon(
            onPressed: _openEmergency,
            icon: const Icon(Icons.favorite),
            label: const Text('Get help'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'resources') {
                _openResources();
              } else if (value == 'history') {
                _openHistory();
              } else if (value == 'start') {
                _goToStart();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'resources', child: Text('Resources')),
              if (AuthService.loggedIn)
                const PopupMenuItem(value: 'history', child: Text('My history')),
              PopupMenuItem(
                value: 'start',
                child: Text(AuthService.loggedIn ? 'Log out' : 'Back to start'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _bubble(_messages[index]),
              ),
            ),
            _choiceButtons(),
            _inputBar(),
          ],
        ),
      ),
    );
  }
}