// A copy of the warning phrases that lives inside the app, so the scan
// still works with no internet. Keep it in sync with WARNING_PHRASES in
// backend/app/core/crisis.py. The final list (including Bisaya, Waray and
// Tagalog phrases) must be written and checked by your guidance counselor
// and native speakers.
const List<String> warningPhrases = [
  'kill myself',
  'suicide',
  'end my life',
  'want to die',
];

bool messageHasWarning(String message) {
  final text = message.toLowerCase();

  for (final phrase in warningPhrases) {
    if (text.contains(phrase)) {
      return true;
    }
  }

  return false;
}