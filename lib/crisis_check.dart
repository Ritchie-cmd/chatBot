import 'phrase_service.dart';

// Built-in English phrases. They are always checked. Phrases that the admin
// added in the app are checked too (see PhraseService). Keep this list in
// sync with WARNING_PHRASES in backend/app/core/crisis.py.
const List<String> warningPhrases = [
  'kill myself',
  'suicide',
  'end my life',
  'want to die',
];

bool messageHasWarning(String message) {
  final text = message.toLowerCase();

  for (final phrase in [...warningPhrases, ...PhraseService.extra]) {
    if (text.contains(phrase)) {
      return true;
    }
  }

  return false;
}