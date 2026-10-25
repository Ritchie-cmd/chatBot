import 'package:flutter/material.dart';

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
  int _current = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _messages.add(const ChatMessage(
      "Hi, I'm Kalinaw. I'll ask a few questions about how you've been feeling. This is a screening, not a diagnosis.",
      false,
    ));
    _messages.add(const ChatMessage(
      'Over the last 2 weeks, how often have you been bothered by:',
      false,
    ));
    _messages.add(ChatMessage(phq9Questions[0], false));
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
        _messages.add(ChatMessage(
          'Thank you for answering. Your answers: $_answers',
          false,
        ));
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kalinaw')),
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
          ],
        ),
      ),
    );
  }
}