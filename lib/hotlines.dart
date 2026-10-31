class Hotline {
  final String name;
  final String number;
  final String note;

  const Hotline({
    required this.name,
    required this.number,
    required this.note,
  });
}

// IMPORTANT: replace these placeholders with numbers that have been
// verified from official sources and approved by your guidance counselor.
// Do not publish the app to real students until this list is final.
const List<Hotline> hotlines = [
  Hotline(
    name: 'National crisis hotline (to be verified)',
    number: 'NUMBER TO BE ADDED',
    note: 'Confirm the current number and hours with your counselor.',
  ),
  Hotline(
    name: 'Emergency services (to be verified)',
    number: 'NUMBER TO BE ADDED',
    note: 'For immediate danger.',
  ),
  Hotline(
    name: 'BPSU guidance office (to be verified)',
    number: 'NUMBER TO BE ADDED',
    note: 'Ask your counselor for the office contact and hours.',
  ),
];