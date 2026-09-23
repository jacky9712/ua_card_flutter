// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageName => 'English';

  @override
  String get navHome => 'Home';

  @override
  String get navDecks => 'Decks';

  @override
  String get navMessages => 'News';

  @override
  String get navProfile => 'Profile';

  @override
  String get fabCreate => 'Build';

  @override
  String get searchHint => 'Search card no. or name...';

  @override
  String get qrImport => 'QR Import';

  @override
  String get bannerPlaceholder => 'Featured Event';

  @override
  String get actionMeta => 'Meta';

  @override
  String get actionDeckBuilder => 'Deck Builder';

  @override
  String get actionMyDecks => 'My Decks';

  @override
  String get actionTopDecks => 'Top Decks';

  @override
  String get actionMatchRecords => 'Match Log';

  @override
  String get actionMeetup => 'Meetups';

  @override
  String get metaTitle => 'Meta';

  @override
  String get seeMore => 'See more >';

  @override
  String get metaEmpty => 'No meta data yet. Pull down to refresh';

  @override
  String get loadFailed => 'Couldn\'t load. Check your connection';

  @override
  String get retry => 'Retry';

  @override
  String get unknownSeries => 'Unknown series';

  @override
  String get guestDialogTitle => 'Profile';

  @override
  String get guestDialogBody =>
      'You\'re using a guest account. Set a nickname so other players can recognize you, or log in / sign up for a full account.';

  @override
  String get myQrCard => 'My QR Card';

  @override
  String get setNickname => 'Set Nickname';

  @override
  String get loginOrRegister => 'Log in / Sign up';

  @override
  String get memberCenter => 'Account';

  @override
  String accountLabel(String email) {
    return 'Account: $email';
  }

  @override
  String nicknameLabel(String name) {
    return 'Nickname: $name';
  }

  @override
  String get nicknameNotSet => '(not set)';

  @override
  String get editNickname => 'Edit Nickname';

  @override
  String get signOut => 'Log out';

  @override
  String get signedOut => 'Logged out';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get note => 'Notes';

  @override
  String get unnamedPlayer => '(Unnamed player)';

  @override
  String get unnamedDeck => 'Untitled deck';

  @override
  String get noSavedDecks => 'No saved decks yet';

  @override
  String get tierOptional => 'Tier (optional, your own rating of this deck)';

  @override
  String get win => 'Win';

  @override
  String get loss => 'Loss';

  @override
  String get draw => 'Draw';

  @override
  String get colorLabel => 'Color';

  @override
  String get colorRed => 'Red';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorYellow => 'Yellow';

  @override
  String get colorPurple => 'Purple';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get translationFailed => 'Translation failed';

  @override
  String get showOriginal => 'Show original';

  @override
  String get translateCardText => 'Translate to English';

  @override
  String get unknownName => 'Unknown name';

  @override
  String get apCost => 'AP Cost';

  @override
  String get effect => 'Effect';

  @override
  String get trigger => 'Trigger';

  @override
  String get priceTrend => 'Price Trend (JPY)';

  @override
  String get noPriceHistory => 'No price history';

  @override
  String get recordMatchTitle => 'Record Match';

  @override
  String get opponent => 'Opponent';

  @override
  String get noKnownOpponents =>
      'No known opponents yet. Scan their QR card to add one, or type a name below';

  @override
  String get scanQrAddOpponent => 'Scan QR to add opponent';

  @override
  String get opponentNameHint =>
      'Or type the opponent\'s name (no account needed)';

  @override
  String get clearSelectedOpponent => 'Clear selection and type a name';

  @override
  String get deckUsedOptional => 'Deck used (optional)';

  @override
  String get result => 'Result';

  @override
  String get noteOptional => 'Notes (optional)';

  @override
  String get matchNoteHint => 'Thoughts, key turns...';

  @override
  String matchRecorded(String name) {
    return '🎉 Recorded match vs. $name';
  }

  @override
  String get saveRecord => 'Save record';

  @override
  String get locationUnavailable =>
      'Couldn\'t get your location. Check that location permission is on';

  @override
  String get locationAttached => 'Current location attached';

  @override
  String get postMeetupTitle => 'Post a Meetup';

  @override
  String get locationName => 'Location name';

  @override
  String get locationNameHint => 'e.g. XX Game Store, 3F';

  @override
  String get coordsAttached => 'Location attached';

  @override
  String get attachCoordsOptional => 'Attach current location (optional)';

  @override
  String get plannedDeckOptional => 'Deck you plan to use (optional)';

  @override
  String get time => 'Time';

  @override
  String get pickTimeOptional => 'Pick a time (optional)';

  @override
  String get meetupNoteHint => 'What decks you want to play, what time...';

  @override
  String get meetupPosted => '🎉 Meetup posted';

  @override
  String get publish => 'Post';

  @override
  String get saveToMyDecks => 'Save to My Decks (done editing)';

  @override
  String get previewBeforeSave => 'Preview before saving';

  @override
  String get costDistribution => 'Cost curve';

  @override
  String get triggerDistribution => 'Trigger breakdown';

  @override
  String get tabCardImages => 'Card images';

  @override
  String get tabImportQr => 'Import QR';

  @override
  String get deckImportQrTitle => 'Deck Import QR Code';

  @override
  String get deckImportQrHint =>
      'Other players can scan this code to import your deck';

  @override
  String get totalCards => 'Total cards';

  @override
  String cardCount(int count) {
    return '$count cards';
  }

  @override
  String get estimatedPrice => 'Est. price (reference)';

  @override
  String energyCost(String value) {
    return '${value}E';
  }

  @override
  String get deckShareTitle => 'Union Arena Deck Share';

  @override
  String totalCardsOf50(int count) {
    return 'Total: $count / 50';
  }

  @override
  String get scanToImportDeck => 'Scan to import deck';

  @override
  String get generatingDeckImage => 'Generating deck image...';

  @override
  String get deckShareText =>
      'Check out the deck I just built with UA Card App!';

  @override
  String get deckShareSubject => 'UA Deck Share';

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get shareDurationTitle => 'Share for how long?';

  @override
  String durationMinutes(int count) {
    return '$count min';
  }

  @override
  String durationHours(int count) {
    return '$count hr';
  }

  @override
  String get shareFailed => 'Sharing failed';

  @override
  String get mobileOnly =>
      'This feature is currently only available on mobile (Android / iOS).';

  @override
  String get sharing => 'Sharing';

  @override
  String get notSharing => 'Not sharing your location';

  @override
  String autoStopAt(String time) {
    return 'Stops automatically at $time';
  }

  @override
  String get stopSharing => 'Stop sharing';

  @override
  String get shareMyLocation => 'Share my location';

  @override
  String get playersSharing => 'Players sharing now';

  @override
  String get noOneSharing => 'No one else is sharing right now';

  @override
  String get locationHubTitle => 'Meetups / Location';

  @override
  String get meetupPostsTab => 'Meetup posts';

  @override
  String get liveLocationTab => 'Live location';

  @override
  String get signUpSuccess => 'Signed up! Check your email to verify.';

  @override
  String get authFailed => 'Authentication failed';

  @override
  String get createAccount => 'Create account';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signUpSubtitle => 'Join UA Card to sync your decks anywhere';

  @override
  String get loginSubtitle => 'Log in to sync your cloud decks';

  @override
  String get email => 'Email';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String get password => 'Password';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get signUpNow => 'Sign up';

  @override
  String get logIn => 'Log in';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get loginShort => 'Log in';

  @override
  String get signUpShort => 'Sign up';

  @override
  String get noMatchRecords => 'No matches recorded yet';

  @override
  String get totalMatches => 'Matches';

  @override
  String get winRate => 'Win rate';

  @override
  String get deckUsed => 'Deck';

  @override
  String get playedAt => 'Played at';

  @override
  String get deleteThisRecord => 'Delete this record';

  @override
  String get deleteRecordTitle => 'Delete match record';

  @override
  String get deleteRecordConfirm =>
      'Delete this record? This can\'t be undone.';

  @override
  String get cancelMeetupTitle => 'Cancel meetup post';

  @override
  String cancelMeetupConfirm(String name) {
    return 'Cancel the post \"$name\"? It will no longer be shown.';
  }

  @override
  String get keep => 'Keep';

  @override
  String get cancelPost => 'Cancel post';

  @override
  String get sortBy => 'Sort: ';

  @override
  String get sortByTime => 'Soonest';

  @override
  String get sortByDistance => 'Nearest';

  @override
  String get noMeetups => 'No meetup posts yet';

  @override
  String get unnamedLocation => 'Unnamed location';

  @override
  String postedBy(String name) {
    return 'Posted by $name';
  }

  @override
  String deckWithName(String name) {
    return 'Deck: $name';
  }

  @override
  String get openMaps => 'Open in Maps';

  @override
  String get recordRelatedMatch => 'Record a match from this meetup';

  @override
  String get metaLeaderboardTitle => 'Meta Rankings';

  @override
  String get noMetaData => 'No meta data yet';

  @override
  String get metaTrend => 'Meta Trends';

  @override
  String updatedAt(String time) {
    return 'Updated: $time';
  }

  @override
  String get totalDecks => 'Total decks';

  @override
  String get activeSeries => 'Active series';

  @override
  String get topShare => 'Top share';

  @override
  String useCount(String count) {
    return 'Used $count times';
  }

  @override
  String get noDecksYet => 'No decks yet — go build one!';

  @override
  String get confirmDelete => 'Confirm delete';

  @override
  String deleteDeckConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String deckDeleted(String name) {
    return 'Deleted deck $name';
  }

  @override
  String get savedOnDevice => 'Saved on this device';

  @override
  String get syncedToCloud => 'Synced to cloud';

  @override
  String get notLoggedIn => 'Not logged in';

  @override
  String get nicknameNotSetLong => '(No nickname set)';

  @override
  String get myQrHint =>
      'Other players can scan this QR to add you as an opponent';

  @override
  String get nicknameExplain =>
      'This name is shown when others add you via QR, and on meetup posts and match logs.';

  @override
  String get nicknameHint => 'Enter a nickname...';

  @override
  String nicknameSet(String name) {
    return 'Nickname set to \"$name\"';
  }

  @override
  String get scanQrTitle => 'Scan QR Code';

  @override
  String get importedDeckName => 'Scanned deck';

  @override
  String get deckImported => '🎉 Deck imported!';

  @override
  String get importFailed => '❌ Import failed: invalid format';

  @override
  String opponentAdded(String name) {
    return '🎉 Added $name as an opponent!';
  }

  @override
  String get addOpponentFailed => 'Failed to add opponent';

  @override
  String get scanQrHint => 'Point at another player\'s deck or profile QR code';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get filter => 'Filter';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get onlyMySeries => 'Only my decks\' series';

  @override
  String get onlyMySeriesHint => 'Show only series from your saved decks';

  @override
  String get series => 'Series';

  @override
  String get tier => 'Tier';

  @override
  String get deckListIncomplete => 'This deck\'s card list isn\'t complete yet';

  @override
  String get recommendedDeck => 'Recommended deck';

  @override
  String get copyToDeckBuilder => 'Copy to Deck Builder';

  @override
  String get topDecksTitle => 'Top Decks';

  @override
  String get noRecommendedDecks => 'No recommended decks yet';

  @override
  String get noDecksMatchFilter => 'No decks match these filters';

  @override
  String get uncategorizedSeries => 'Uncategorized series';

  @override
  String winRateValue(String rate) {
    return 'Win rate $rate%';
  }

  @override
  String get newDeckPreview => 'New deck preview';

  @override
  String get deckBuilderMode => 'Deck Builder';

  @override
  String get noCardsFound => 'No matching cards';

  @override
  String currentCardCount(int count) {
    return 'Cards: $count / 50';
  }

  @override
  String totalPrice(String price) {
    return 'Total: ¥ $price';
  }

  @override
  String get previewAndSave => 'Preview & Save';

  @override
  String get allSeries => 'All series';

  @override
  String get selectSeries => 'Select series';

  @override
  String get selectColor => 'Select color';

  @override
  String get allColors => 'All colors';

  @override
  String get saveDeck => 'Save deck';

  @override
  String get deckNameHint => 'Enter deck name...';

  @override
  String deckSaved(String name) {
    return '🎉 Deck \"$name\" saved!';
  }

  @override
  String get saveFailed => 'Save failed. Please try again later';

  @override
  String get confirmSave => 'Save';

  @override
  String get startupErrorTitle => 'Couldn\'t start the app';

  @override
  String get startupErrorBody =>
      'Failed to load the server settings. Please update to the latest version or try again later. If this keeps happening, send us the message below.';

  @override
  String get openNewsFailed => 'Couldn\'t open the official news page';
}
