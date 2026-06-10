/// Daily motivation quotes. Three sources rotate so the user gets
/// scripture, timeless wisdom, and Solo Leveling fire to keep getting stronger.
enum QuoteSource { bible, wisdom, soloLeveling }

class Quote {
  final String text;
  final String author;
  final QuoteSource source;
  const Quote(this.text, this.author, this.source);

  String get sourceLabel {
    switch (source) {
      case QuoteSource.bible:
        return 'SCRIPTURE';
      case QuoteSource.wisdom:
        return 'WISDOM';
      case QuoteSource.soloLeveling:
        return 'THE SYSTEM';
    }
  }
}

const List<Quote> _bible = [
  Quote('I can do all things through Christ who strengthens me.',
      'Philippians 4:13', QuoteSource.bible),
  Quote('Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go.',
      'Joshua 1:9', QuoteSource.bible),
  Quote('But those who hope in the Lord will renew their strength. They will soar on wings like eagles; they will run and not grow weary.',
      'Isaiah 40:31', QuoteSource.bible),
  Quote('She is clothed with strength and dignity, and she laughs without fear of the future.',
      'Proverbs 31:25', QuoteSource.bible),
  Quote('The Lord is my strength and my shield; my heart trusts in him, and he helps me.',
      'Psalm 28:7', QuoteSource.bible),
  Quote('Do you not know that in a race all the runners run, but only one gets the prize? Run in such a way as to get the prize.',
      '1 Corinthians 9:24', QuoteSource.bible),
  Quote('Let us not become weary in doing good, for at the proper time we will reap a harvest if we do not give up.',
      'Galatians 6:9', QuoteSource.bible),
  Quote('No discipline seems pleasant at the time, but painful. Later on, however, it produces a harvest of righteousness and peace.',
      'Hebrews 12:11', QuoteSource.bible),
  Quote('I have fought the good fight, I have finished the race, I have kept the faith.',
      '2 Timothy 4:7', QuoteSource.bible),
  Quote('Watch, stand fast in the faith, be brave, be strong.',
      '1 Corinthians 16:13', QuoteSource.bible),
  Quote('Therefore we do not lose heart. Though outwardly we are wasting away, yet inwardly we are being renewed day by day.',
      '2 Corinthians 4:16', QuoteSource.bible),
  Quote('Commit to the Lord whatever you do, and he will establish your plans.',
      'Proverbs 16:3', QuoteSource.bible),
];

const List<Quote> _wisdom = [
  Quote('It does not matter how slowly you go as long as you do not stop.',
      'Confucius', QuoteSource.wisdom),
  Quote('The body achieves what the mind believes.', 'Napoleon Hill',
      QuoteSource.wisdom),
  Quote('We are what we repeatedly do. Excellence, then, is not an act, but a habit.',
      'Aristotle', QuoteSource.wisdom),
  Quote('Discipline is choosing between what you want now and what you want most.',
      'Abraham Lincoln', QuoteSource.wisdom),
  Quote('The successful warrior is the average man, with laser-like focus.',
      'Bruce Lee', QuoteSource.wisdom),
  Quote('Strength does not come from winning. Your struggles develop your strengths.',
      'Arnold Schwarzenegger', QuoteSource.wisdom),
  Quote('You must expect great things of yourself before you can do them.',
      'Michael Jordan', QuoteSource.wisdom),
  Quote('Fall seven times, stand up eight.', 'Japanese Proverb',
      QuoteSource.wisdom),
  Quote('The pain you feel today will be the strength you feel tomorrow.',
      'Unknown', QuoteSource.wisdom),
  Quote('Do something today that your future self will thank you for.',
      'Sean Patrick Flanery', QuoteSource.wisdom),
  Quote('A river cuts through rock not because of its power but its persistence.',
      'Jim Watkins', QuoteSource.wisdom),
  Quote('The only way out is through, and the only way through is forward.',
      'Stoic Maxim', QuoteSource.wisdom),
  Quote('Hard choices, easy life. Easy choices, hard life.',
      'Jerzy Gregorek', QuoteSource.wisdom),
  Quote('No man has the right to be an amateur in the matter of physical training.',
      'Socrates', QuoteSource.wisdom),
];

const List<Quote> _soloLeveling = [
  Quote('I used to think I was the weakest. So I decided to become the strongest.',
      'Sung Jinwoo', QuoteSource.soloLeveling),
  Quote('If I let this fear stop me here, then nothing about me will change. I have to keep moving forward.',
      'Sung Jinwoo', QuoteSource.soloLeveling),
  Quote('Only those who fight will survive. The weak get nothing.',
      'The System', QuoteSource.soloLeveling),
  Quote('I am no longer the weakest. Every day I grow stronger.',
      'Sung Jinwoo', QuoteSource.soloLeveling),
  Quote('A quest has been issued. Complete it, and grow beyond your limits.',
      'The System', QuoteSource.soloLeveling),
  Quote('Pain is temporary. Becoming stronger is forever. Arise.',
      'Shadow Monarch', QuoteSource.soloLeveling),
  Quote('I will not be hunted. I will become the hunter.',
      'Sung Jinwoo', QuoteSource.soloLeveling),
  Quote('Daily quest incomplete. The penalty zone awaits the weak. Rise and finish what you started.',
      'The System', QuoteSource.soloLeveling),
  Quote('Strength is not given. It is earned, one quest at a time.',
      'The System', QuoteSource.soloLeveling),
  Quote('The difference between a powerful person and a weak one is whether they have the will to keep going.',
      'Sung Jinwoo', QuoteSource.soloLeveling),
  Quote('Level up. There is no ceiling for those who refuse to stop.',
      'The System', QuoteSource.soloLeveling),
  Quote('I have to get stronger. No matter what it takes.',
      'Sung Jinwoo', QuoteSource.soloLeveling),
];

final List<Quote> kAllQuotes = [..._bible, ..._wisdom, ..._soloLeveling];

/// Deterministic quote for a given day, cycling evenly across all sources so
/// the same date always shows the same quote (and notification matches the UI).
Quote quoteForDay(DateTime day) {
  final epochDay = day.toUtc().difference(DateTime.utc(2024, 1, 1)).inDays;
  final idx = epochDay.abs() % kAllQuotes.length;
  return kAllQuotes[idx];
}

/// A fiery one-liner used for notification bodies when a quest is unfinished.
Quote pushQuoteForDay(DateTime day) {
  final epochDay = day.toUtc().difference(DateTime.utc(2024, 1, 1)).inDays;
  return _soloLeveling[epochDay.abs() % _soloLeveling.length];
}
