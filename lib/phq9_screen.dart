import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'crisis_check.dart';
import 'emergency_screen.dart';

// Change this one line when the backend moves to a real server.
const String backendUrl = 'http://127.0.0.1:8000';

// Wording follows the standard PHQ-9. Your guidance counselor should
// confirm the exact text (and any translation) before real use.
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
  int _current = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _messages.add(const ChatMessage(
      "Hi, I'm Kalinaw. You can type how you're feeling anytime, or answer a few questions. This is a screening, not a diagnosis.",
      false,
    ));
    _messages.add(const ChatMessage(
      'Over the last 2 weeks, how often have you been bothered by:',
      false,
    ));
    _messages.add(ChatMessage(phq9Questions[0], false));
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
      final bool crisis = data['crisis'];

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
            "Thank you for telling me. I'm listening. Whenever you're ready, you can keep answering the questions below.",
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

      if (_current < phq9Questions.length) {
        _messages.add(ChatMessage(phq9Questions[_current], false));
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
        Uri.parse('$backendUrl/screen/phq9'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'answers': _answers}),
      );

      if (response.statusCode != 200) {
        throw Exception('Unexpected response: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final int total = data['total'];
      final String level = data['level'];
      final bool crisis = data['crisis'];

      if (!mounted) return;

      setState(() {
        if (crisis) {
          _messages.add(const ChatMessage(crisisText, false));
        }

        _messages.add(ChatMessage(
          'Your total score is $total out of 27. Level: $level.',
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
            if (!_finished)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int i = 0; i < answerLabels.length; i++)
                      ElevatedButton(
                        onPressed: () => _answer(i),
                        child: Text(answerLabels[i]),
                      ),
                  ],
                ),
              ),
            _inputBar(),
          ],
        ),
      ),
    );
  }
}