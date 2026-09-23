// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get languageName => '日本語';

  @override
  String get navHome => 'ホーム';

  @override
  String get navDecks => 'デッキ';

  @override
  String get navMessages => 'ニュース';

  @override
  String get navProfile => 'マイページ';

  @override
  String get searchHint => 'カード番号・カード名で検索...';

  @override
  String get qrImport => 'QR読込';

  @override
  String get bannerPlaceholder => '注目イベント';

  @override
  String get actionMeta => '環境分析';

  @override
  String get actionDeckBuilder => 'デッキ作成';

  @override
  String get actionMyDecks => 'マイデッキ';

  @override
  String get actionTopDecks => '上位デッキ';

  @override
  String get actionMatchRecords => '対戦記録';

  @override
  String get actionMeetup => '対戦場所';

  @override
  String get metaTitle => '環境分析';

  @override
  String get seeMore => 'もっと見る >';

  @override
  String get metaEmpty => '環境データがありません。下に引いて更新してください';

  @override
  String get unknownSeries => '不明なシリーズ';

  @override
  String get guestDialogTitle => 'プロフィール設定';

  @override
  String get guestDialogBody =>
      '現在ゲストとして利用中です。ニックネームを設定して他のプレイヤーに知ってもらうか、正式アカウントでログイン/登録できます。';

  @override
  String get myQrCard => 'マイQR名刺';

  @override
  String get setNickname => 'ニックネーム設定';

  @override
  String get loginOrRegister => 'ログイン/登録';

  @override
  String get memberCenter => '会員センター';

  @override
  String accountLabel(String email) {
    return 'アカウント: $email';
  }

  @override
  String nicknameLabel(String name) {
    return 'ニックネーム: $name';
  }

  @override
  String get nicknameNotSet => '（未設定）';

  @override
  String get editNickname => 'ニックネーム編集';

  @override
  String get signOut => 'ログアウト';

  @override
  String get signedOut => 'ログアウトしました';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get save => '保存';

  @override
  String get done => '完了';

  @override
  String get note => 'メモ';

  @override
  String get unnamedPlayer => '（名前未設定）';

  @override
  String get unnamedDeck => '無題のデッキ';

  @override
  String get noSavedDecks => '保存済みのデッキはありません';

  @override
  String get tierOptional => 'Tier（任意・デッキの強さを自己評価）';

  @override
  String get win => '勝ち';

  @override
  String get loss => '負け';

  @override
  String get draw => '引き分け';

  @override
  String get colorLabel => '色';

  @override
  String get colorRed => '赤';

  @override
  String get colorBlue => '青';

  @override
  String get colorGreen => '緑';

  @override
  String get colorYellow => '黄';

  @override
  String get colorPurple => '紫';

  @override
  String errorWithMessage(String message) {
    return 'エラー: $message';
  }

  @override
  String get translationFailed => '翻訳に失敗しました';

  @override
  String get showOriginal => '原文を表示';

  @override
  String get translateCardText => '翻訳';

  @override
  String get unknownName => '名称不明';

  @override
  String get apCost => '消費AP';

  @override
  String get effect => '効果';

  @override
  String get trigger => 'トリガー';

  @override
  String get priceTrend => '価格推移 (JPY)';

  @override
  String get noPriceHistory => '価格履歴がありません';

  @override
  String get recordMatchTitle => '対戦結果を記録';

  @override
  String get opponent => '対戦相手';

  @override
  String get noKnownOpponents =>
      'まだ登録済みの対戦相手がいません。相手のQR名刺をスキャンして追加するか、下に名前を入力してください';

  @override
  String get scanQrAddOpponent => 'QRで対戦相手を追加';

  @override
  String get opponentNameHint => 'または対戦相手の名前を入力（アカウントなしでも記録可）';

  @override
  String get clearSelectedOpponent => '選択を解除して名前を入力';

  @override
  String get deckUsedOptional => '使用デッキ（任意）';

  @override
  String get result => '結果';

  @override
  String get noteOptional => 'メモ（任意）';

  @override
  String get matchNoteHint => 'この対戦の感想やキーターンなど...';

  @override
  String matchRecorded(String name) {
    return '🎉 「$name」との対戦を記録しました';
  }

  @override
  String get saveRecord => '記録を保存';

  @override
  String get locationUnavailable => '現在地を取得できません。位置情報の権限を確認してください';

  @override
  String get locationAttached => '現在地の座標を添付しました';

  @override
  String get postMeetupTitle => '対戦場所を投稿';

  @override
  String get locationName => '場所名';

  @override
  String get locationNameHint => '例：〇〇カードショップ 3階';

  @override
  String get coordsAttached => '座標を添付済み';

  @override
  String get attachCoordsOptional => '現在地の座標を添付（任意）';

  @override
  String get plannedDeckOptional => '使う予定のデッキ（任意）';

  @override
  String get time => '日時';

  @override
  String get pickTimeOptional => '日時を選択（任意）';

  @override
  String get meetupNoteHint => 'どんなデッキと対戦したいか、何時から何時まで...';

  @override
  String get meetupPosted => '🎉 対戦募集を投稿しました';

  @override
  String get publish => '投稿';

  @override
  String get saveToMyDecks => 'マイデッキに保存（編集完了）';

  @override
  String get previewBeforeSave => '保存前プレビュー';

  @override
  String get costDistribution => 'コスト分布';

  @override
  String get triggerDistribution => 'トリガー分布';

  @override
  String get tabCardImages => 'カード画像';

  @override
  String get tabImportQr => 'インポートQR';

  @override
  String get deckImportQrTitle => 'デッキインポート QRコード';

  @override
  String get deckImportQrHint => '他のプレイヤーがこのコードをスキャンするとデッキをインポートできます';

  @override
  String get totalCards => '合計枚数';

  @override
  String cardCount(int count) {
    return '$count 枚';
  }

  @override
  String get estimatedPrice => '参考価格';

  @override
  String energyCost(String value) {
    return '${value}E';
  }

  @override
  String get deckShareTitle => 'Union Arena デッキ共有';

  @override
  String totalCardsOf50(int count) {
    return '合計枚数: $count / 50';
  }

  @override
  String get scanToImportDeck => 'スキャンでデッキをインポート';

  @override
  String get generatingDeckImage => 'デッキ画像を作成中...';

  @override
  String get deckShareText => 'UA Card App で組んだデッキです！';

  @override
  String get deckShareSubject => 'UA デッキ共有';

  @override
  String exportFailed(String error) {
    return 'エクスポートに失敗しました: $error';
  }

  @override
  String get shareDurationTitle => '共有する時間は？';

  @override
  String durationMinutes(int count) {
    return '$count分';
  }

  @override
  String durationHours(int count) {
    return '$count時間';
  }

  @override
  String get shareFailed => '共有に失敗しました';

  @override
  String get mobileOnly => 'この機能は現在スマートフォン（Android / iOS）のみ対応しています。';

  @override
  String get sharing => '共有中';

  @override
  String get notSharing => '位置情報を共有していません';

  @override
  String autoStopAt(String time) {
    return '$time に自動停止';
  }

  @override
  String get stopSharing => '共有を停止';

  @override
  String get shareMyLocation => '現在地を共有';

  @override
  String get playersSharing => '現在共有中のプレイヤー';

  @override
  String get noOneSharing => '他に共有中のプレイヤーはいません';

  @override
  String get locationHubTitle => '対戦募集 / 位置共有';

  @override
  String get meetupPostsTab => '対戦募集';

  @override
  String get liveLocationTab => 'リアルタイム位置';

  @override
  String get signUpSuccess => '登録しました！確認メールをご確認ください。';

  @override
  String get authFailed => '認証に失敗しました';

  @override
  String get createAccount => '新規アカウント作成';

  @override
  String get welcomeBack => 'おかえりなさい';

  @override
  String get signUpSubtitle => 'UA Card に登録していつでもデッキを同期';

  @override
  String get loginSubtitle => 'ログインしてクラウドのデッキを同期';

  @override
  String get email => 'メールアドレス';

  @override
  String get invalidEmail => '有効なメールアドレスを入力してください';

  @override
  String get password => 'パスワード';

  @override
  String get passwordTooShort => 'パスワードは6文字以上必要です';

  @override
  String get signUpNow => '今すぐ登録';

  @override
  String get logIn => 'ログイン';

  @override
  String get haveAccount => 'アカウントをお持ちですか？';

  @override
  String get noAccount => 'アカウントをお持ちでないですか？';

  @override
  String get loginShort => 'ログイン';

  @override
  String get signUpShort => '登録';

  @override
  String get noMatchRecords => '対戦記録はまだありません';

  @override
  String get totalMatches => '総対戦数';

  @override
  String get winRate => '勝率';

  @override
  String get deckUsed => '使用デッキ';

  @override
  String get playedAt => '対戦日時';

  @override
  String get deleteThisRecord => 'この記録を削除';

  @override
  String get deleteRecordTitle => '対戦記録を削除';

  @override
  String get deleteRecordConfirm => 'この記録を削除しますか？元に戻せません。';

  @override
  String get cancelMeetupTitle => '対戦募集を取り消す';

  @override
  String cancelMeetupConfirm(String name) {
    return '「$name」の投稿を取り消しますか？取り消すと表示されなくなります。';
  }

  @override
  String get keep => '残す';

  @override
  String get cancelPost => '投稿を取り消す';

  @override
  String get sortBy => '並び順：';

  @override
  String get sortByTime => '日時が近い順';

  @override
  String get sortByDistance => '距離が近い順';

  @override
  String get noMeetups => '対戦募集はまだありません';

  @override
  String get unnamedLocation => '場所未設定';

  @override
  String postedBy(String name) {
    return '投稿者: $name';
  }

  @override
  String deckWithName(String name) {
    return 'デッキ: $name';
  }

  @override
  String get openMaps => '地図アプリで開く';

  @override
  String get recordRelatedMatch => 'この募集の対戦を記録';

  @override
  String get metaLeaderboardTitle => '環境ランキング';

  @override
  String get noMetaData => '環境データがありません';

  @override
  String get metaTrend => '環境トレンド分析';

  @override
  String updatedAt(String time) {
    return '更新: $time';
  }

  @override
  String get totalDecks => '総デッキ数';

  @override
  String get activeSeries => 'アクティブシリーズ';

  @override
  String get topShare => 'トップシェア';

  @override
  String useCount(String count) {
    return '使用回数: $count 回';
  }

  @override
  String get noDecksYet => 'まだデッキがありません。さっそく作ってみましょう！';

  @override
  String get confirmDelete => '削除の確認';

  @override
  String deleteDeckConfirm(String name) {
    return '「$name」を削除しますか？';
  }

  @override
  String deckDeleted(String name) {
    return 'デッキ「$name」を削除しました';
  }

  @override
  String get savedOnDevice => 'この端末に保存';

  @override
  String get syncedToCloud => 'クラウドに同期済み';

  @override
  String get notLoggedIn => '未ログイン';

  @override
  String get nicknameNotSetLong => '（ニックネーム未設定）';

  @override
  String get myQrHint => '他のプレイヤーがこのQRをスキャンすると、あなたを対戦相手として追加できます';

  @override
  String get nicknameExplain => 'QRでの対戦相手追加、対戦募集、対戦記録でこの名前が表示されます。';

  @override
  String get nicknameHint => 'ニックネームを入力...';

  @override
  String nicknameSet(String name) {
    return 'ニックネームを「$name」に設定しました';
  }

  @override
  String get scanQrTitle => 'QRコードをスキャン';

  @override
  String get importedDeckName => 'スキャンしたデッキ';

  @override
  String get deckImported => '🎉 デッキをインポートしました！';

  @override
  String get importFailed => '❌ インポート失敗：形式が正しくありません';

  @override
  String opponentAdded(String name) {
    return '🎉 「$name」を対戦相手に追加しました！';
  }

  @override
  String get addOpponentFailed => '対戦相手の追加に失敗しました';

  @override
  String get scanQrHint => '他のプレイヤーのデッキまたはプロフィールのQRコードを枠に合わせてください';

  @override
  String get uncategorized => '未分類';

  @override
  String get filter => '絞り込み';

  @override
  String get clearFilters => '絞り込みをクリア';

  @override
  String get onlyMySeries => 'マイデッキのシリーズのみ';

  @override
  String get onlyMySeriesHint => '「マイデッキ」にあるシリーズのみ表示';

  @override
  String get series => 'シリーズ';

  @override
  String get tier => 'Tier';

  @override
  String get deckListIncomplete => 'このデッキのカードリストはまだ完成していません';

  @override
  String get recommendedDeck => 'おすすめデッキ';

  @override
  String get copyToDeckBuilder => 'デッキ作成にコピー';

  @override
  String get topDecksTitle => '上位デッキ';

  @override
  String get noRecommendedDecks => 'おすすめデッキはまだありません';

  @override
  String get noDecksMatchFilter => '条件に合うデッキがありません';

  @override
  String get uncategorizedSeries => '未分類シリーズ';

  @override
  String winRateValue(String rate) {
    return '勝率 $rate%';
  }

  @override
  String get newDeckPreview => '新規デッキのプレビュー';

  @override
  String get deckBuilderMode => 'デッキ作成';

  @override
  String get noCardsFound => '該当するカードがありません';

  @override
  String currentCardCount(int count) {
    return '現在の枚数: $count / 50';
  }

  @override
  String totalPrice(String price) {
    return '合計金額: ¥ $price';
  }

  @override
  String get previewAndSave => 'プレビューして保存';

  @override
  String get allSeries => 'すべてのシリーズ';

  @override
  String get selectSeries => 'シリーズを選択';

  @override
  String get selectColor => '色を選択';

  @override
  String get allColors => 'すべての色';

  @override
  String get saveDeck => 'デッキを保存';

  @override
  String get deckNameHint => 'デッキ名を入力...';

  @override
  String deckSaved(String name) {
    return '🎉 デッキ「$name」を保存しました！';
  }

  @override
  String get saveFailed => '保存に失敗しました。しばらくしてから再試行してください';

  @override
  String get confirmSave => '保存する';

  @override
  String get startupErrorTitle => 'アプリを起動できません';

  @override
  String get startupErrorBody =>
      'サーバー設定の読み込みに失敗しました。最新版に更新するか、しばらくしてから再度お試しください。問題が続く場合は、下のメッセージを添えてご連絡ください。';

  @override
  String get openNewsFailed => '公式サイトのニュースを開けませんでした';
}
