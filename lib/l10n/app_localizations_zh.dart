// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get languageName => '繁體中文';

  @override
  String get navHome => '首頁';

  @override
  String get navDecks => '牌組';

  @override
  String get navMessages => '消息';

  @override
  String get navProfile => '個人';

  @override
  String get fabCreate => '出品';

  @override
  String get searchHint => '搜尋卡號或卡名...';

  @override
  String get qrImport => 'QR導入';

  @override
  String get bannerPlaceholder => '熱門活動橫幅';

  @override
  String get actionMeta => '對戰環境';

  @override
  String get actionDeckBuilder => '智能組牌';

  @override
  String get actionMyDecks => '我的牌組';

  @override
  String get actionTopDecks => '上位卡組';

  @override
  String get actionMatchRecords => '戰績紀錄';

  @override
  String get actionMeetup => '約戰地點';

  @override
  String get metaTitle => '對戰環境';

  @override
  String get seeMore => '查看更多 >';

  @override
  String get metaEmpty => '暫無對戰環境資料，下拉重新整理';

  @override
  String get unknownSeries => '未知系列';

  @override
  String get guestDialogTitle => '個人設定';

  @override
  String get guestDialogBody => '你目前是訪客身分。可以先設定暱稱讓其他玩家認得你，或是登入/註冊正式帳號。';

  @override
  String get myQrCard => '我的 QR 名片';

  @override
  String get setNickname => '設定暱稱';

  @override
  String get loginOrRegister => '登入/註冊';

  @override
  String get memberCenter => '會員中心';

  @override
  String accountLabel(String email) {
    return '帳號: $email';
  }

  @override
  String nicknameLabel(String name) {
    return '暱稱: $name';
  }

  @override
  String get nicknameNotSet => '（尚未設定）';

  @override
  String get editNickname => '編輯暱稱';

  @override
  String get signOut => '登出帳號';

  @override
  String get signedOut => '已成功登出';

  @override
  String get cancel => '取消';

  @override
  String get delete => '刪除';

  @override
  String get save => '儲存';

  @override
  String get done => '完成';

  @override
  String get note => '備註';

  @override
  String get unnamedPlayer => '（未命名玩家）';

  @override
  String get unnamedDeck => '未命名牌組';

  @override
  String get noSavedDecks => '目前沒有已存的牌組';

  @override
  String get tierOptional => 'T 級（選填，自己評估這副牌組的強度）';

  @override
  String get win => '勝';

  @override
  String get loss => '敗';

  @override
  String get draw => '平手';

  @override
  String get colorLabel => '顏色';

  @override
  String get colorRed => '紅';

  @override
  String get colorBlue => '藍';

  @override
  String get colorGreen => '綠';

  @override
  String get colorYellow => '黃';

  @override
  String get colorPurple => '紫';

  @override
  String errorWithMessage(String message) {
    return '錯誤: $message';
  }

  @override
  String get translationFailed => '翻譯失敗';

  @override
  String get showOriginal => '顯示原文';

  @override
  String get translateCardText => '中文翻譯';

  @override
  String get unknownName => '未知名稱';

  @override
  String get apCost => 'AP 消耗';

  @override
  String get effect => '效果';

  @override
  String get trigger => '觸發 (Trigger)';

  @override
  String get priceTrend => '價格趨勢 (JPY)';

  @override
  String get noPriceHistory => '暫無歷史價格數據';

  @override
  String get recordMatchTitle => '紀錄對戰結果';

  @override
  String get opponent => '對手';

  @override
  String get noKnownOpponents => '還沒有已知對手，先掃對方的 QR 名片加一個，或直接在下面輸入名字';

  @override
  String get scanQrAddOpponent => '掃 QR 新增對手';

  @override
  String get opponentNameHint => '或者直接輸入對手名字（沒有帳號也能記）';

  @override
  String get clearSelectedOpponent => '取消已選的對手，改用文字輸入';

  @override
  String get deckUsedOptional => '使用的牌組（選填）';

  @override
  String get result => '結果';

  @override
  String get noteOptional => '備註（選填）';

  @override
  String get matchNoteHint => '這場對戰的心得、關鍵回合...';

  @override
  String matchRecorded(String name) {
    return '🎉 已記錄與「$name」的對戰';
  }

  @override
  String get saveRecord => '儲存紀錄';

  @override
  String get locationUnavailable => '無法取得目前位置，請確認定位權限已開啟';

  @override
  String get locationAttached => '已附上目前位置座標';

  @override
  String get postMeetupTitle => '發布約戰地點';

  @override
  String get locationName => '地點名稱';

  @override
  String get locationNameHint => '例如：OO 桌遊店 3 樓';

  @override
  String get coordsAttached => '已附上目前座標';

  @override
  String get attachCoordsOptional => '附上目前位置座標（選填）';

  @override
  String get plannedDeckOptional => '打算用的牌組（選填）';

  @override
  String get time => '時間';

  @override
  String get pickTimeOptional => '選擇時間（選填）';

  @override
  String get meetupNoteHint => '想約什麼牌組、幾點到幾點...';

  @override
  String get meetupPosted => '🎉 約戰貼文已發布';

  @override
  String get publish => '發布';

  @override
  String get saveToMyDecks => '儲存至我的牌組 (完成編輯)';

  @override
  String get previewBeforeSave => '儲存前預覽';

  @override
  String get costDistribution => '成本分佈';

  @override
  String get triggerDistribution => '觸發分佈';

  @override
  String get tabCardImages => '卡片圖像';

  @override
  String get tabImportQr => '導入 QR';

  @override
  String get deckImportQrTitle => '牌組導入 QR Code';

  @override
  String get deckImportQrHint => '其他玩家掃描此碼即可快速導入您的牌組';

  @override
  String get totalCards => '總張數';

  @override
  String cardCount(int count) {
    return '$count 枚';
  }

  @override
  String get estimatedPrice => '預估價格 (參考)';

  @override
  String energyCost(String value) {
    return '$value 能';
  }

  @override
  String get deckShareTitle => 'Union Arena 牌組分享';

  @override
  String totalCardsOf50(int count) {
    return '總張數: $count / 50';
  }

  @override
  String get scanToImportDeck => '掃描導入牌組';

  @override
  String get generatingDeckImage => '正在產生牌組圖片...';

  @override
  String get deckShareText => '這是我剛用 UA Card App 組好的牌組，強吧！';

  @override
  String get deckShareSubject => 'UA 牌組分享';

  @override
  String exportFailed(String error) {
    return '匯出失敗: $error';
  }

  @override
  String get shareDurationTitle => '分享多久？';

  @override
  String durationMinutes(int count) {
    return '$count 分鐘';
  }

  @override
  String durationHours(int count) {
    return '$count 小時';
  }

  @override
  String get shareFailed => '分享失敗';

  @override
  String get mobileOnly => '此功能目前僅支援手機（Android / iOS）。桌面版的定位支援不穩定，先不開放。';

  @override
  String get sharing => '分享中';

  @override
  String get notSharing => '目前沒有分享位置';

  @override
  String autoStopAt(String time) {
    return '將於 $time 自動停止';
  }

  @override
  String get stopSharing => '停止分享';

  @override
  String get shareMyLocation => '分享我的位置';

  @override
  String get playersSharing => '目前分享中的玩家';

  @override
  String get noOneSharing => '目前沒有其他人在分享位置';

  @override
  String get locationHubTitle => '約戰 / 位置分享';

  @override
  String get meetupPostsTab => '約戰貼文';

  @override
  String get liveLocationTab => '即時位置';

  @override
  String get signUpSuccess => '註冊成功！請檢查信箱驗證。';

  @override
  String get authFailed => '認證失敗';

  @override
  String get createAccount => '建立新帳號';

  @override
  String get welcomeBack => '歡迎回來';

  @override
  String get signUpSubtitle => '加入 UA Card 隨時同步您的牌組';

  @override
  String get loginSubtitle => '登入以同步您的雲端牌組';

  @override
  String get email => '電子郵件';

  @override
  String get invalidEmail => '請輸入有效的 Email';

  @override
  String get password => '密碼';

  @override
  String get passwordTooShort => '密碼至少需要 6 位數';

  @override
  String get signUpNow => '立即註冊';

  @override
  String get logIn => '登入帳號';

  @override
  String get haveAccount => '已經有帳號了？';

  @override
  String get noAccount => '還沒有帳號嗎？';

  @override
  String get loginShort => '登入';

  @override
  String get signUpShort => '註冊';

  @override
  String get noMatchRecords => '還沒有任何對戰紀錄';

  @override
  String get totalMatches => '總場次';

  @override
  String get winRate => '勝率';

  @override
  String get deckUsed => '使用牌組';

  @override
  String get playedAt => '對戰時間';

  @override
  String get deleteThisRecord => '刪除這筆紀錄';

  @override
  String get deleteRecordTitle => '刪除對戰紀錄';

  @override
  String get deleteRecordConfirm => '確定要刪除這筆紀錄嗎？刪除後無法復原。';

  @override
  String get cancelMeetupTitle => '取消約戰貼文';

  @override
  String cancelMeetupConfirm(String name) {
    return '確定要取消「$name」這則貼文嗎？取消後就不會再顯示。';
  }

  @override
  String get keep => '保留';

  @override
  String get cancelPost => '取消貼文';

  @override
  String get sortBy => '排序：';

  @override
  String get sortByTime => '最近時間';

  @override
  String get sortByDistance => '最近距離';

  @override
  String get noMeetups => '目前沒有約戰貼文';

  @override
  String get unnamedLocation => '未命名地點';

  @override
  String postedBy(String name) {
    return '發布者: $name';
  }

  @override
  String deckWithName(String name) {
    return '牌組: $name';
  }

  @override
  String get openMaps => '開啟地圖 App';

  @override
  String get recordRelatedMatch => '記錄與此相關的對戰';

  @override
  String get metaLeaderboardTitle => '對戰環境排行榜';

  @override
  String get noMetaData => '目前尚無環境資料';

  @override
  String get metaTrend => '環境趨勢分析';

  @override
  String updatedAt(String time) {
    return '更新於: $time';
  }

  @override
  String get totalDecks => '總計牌組';

  @override
  String get activeSeries => '活躍系列';

  @override
  String get topShare => '主流占比';

  @override
  String useCount(String count) {
    return '使用次數: $count 次';
  }

  @override
  String get noDecksYet => '目前還沒有任何牌組，快去組一套吧！';

  @override
  String get confirmDelete => '確認刪除';

  @override
  String deleteDeckConfirm(String name) {
    return '確定要刪除「$name」嗎？';
  }

  @override
  String deckDeleted(String name) {
    return '已刪除牌組 $name';
  }

  @override
  String get savedOnDevice => '儲存於此裝置';

  @override
  String get syncedToCloud => '已同步至雲端';

  @override
  String get notLoggedIn => '尚未登入';

  @override
  String get nicknameNotSetLong => '（尚未設定暱稱）';

  @override
  String get myQrHint => '讓其他玩家掃描這個 QR，就能把你加為已知對手';

  @override
  String get nicknameExplain => '掃 QR 加對手、約戰貼文、戰績紀錄都會用這個名字讓別人認出你。';

  @override
  String get nicknameHint => '輸入暱稱...';

  @override
  String nicknameSet(String name) {
    return '暱稱已設為「$name」';
  }

  @override
  String get scanQrTitle => '掃描 QR Code';

  @override
  String get importedDeckName => '掃描導入的牌組';

  @override
  String get deckImported => '🎉 牌組導入成功！';

  @override
  String get importFailed => '❌ 導入失敗，格式不正確';

  @override
  String opponentAdded(String name) {
    return '🎉 已將「$name」加為對手！';
  }

  @override
  String get addOpponentFailed => '新增對手失敗';

  @override
  String get scanQrHint => '請對準其他玩家分享的牌組或個人 QR Code';

  @override
  String get uncategorized => '未分類';

  @override
  String get filter => '篩選';

  @override
  String get clearFilters => '清除篩選';

  @override
  String get onlyMySeries => '只看我的卡組系列';

  @override
  String get onlyMySeriesHint => '只顯示「我的牌組」頁面裡有的系列';

  @override
  String get series => '系列';

  @override
  String get tier => 'T 級';

  @override
  String get deckListIncomplete => '這組牌組尚未建立完整卡表';

  @override
  String get recommendedDeck => '推薦牌組';

  @override
  String get copyToDeckBuilder => '複製到組牌編輯器';

  @override
  String get topDecksTitle => '上位卡組推薦';

  @override
  String get noRecommendedDecks => '目前尚無推薦牌組';

  @override
  String get noDecksMatchFilter => '沒有符合篩選條件的牌組';

  @override
  String get uncategorizedSeries => '未分類系列';

  @override
  String winRateValue(String rate) {
    return '勝率 $rate%';
  }

  @override
  String get newDeckPreview => '新牌組預覽';

  @override
  String get deckBuilderMode => '組牌模式';

  @override
  String get noCardsFound => '找不到符合的卡片';

  @override
  String currentCardCount(int count) {
    return '目前張數: $count / 50';
  }

  @override
  String totalPrice(String price) {
    return '總金額: ¥ $price';
  }

  @override
  String get previewAndSave => '預覽並儲存';

  @override
  String get allSeries => '全部系列';

  @override
  String get selectSeries => '選擇系列';

  @override
  String get selectColor => '選擇顏色';

  @override
  String get allColors => '全部顏色';

  @override
  String get saveDeck => '儲存牌組';

  @override
  String get deckNameHint => '輸入牌組名稱...';

  @override
  String deckSaved(String name) {
    return '🎉 牌組「$name」儲存成功！';
  }

  @override
  String get saveFailed => '儲存失敗，請稍後再試';

  @override
  String get confirmSave => '確認儲存';

  @override
  String get startupErrorTitle => '無法啟動 App';

  @override
  String get startupErrorBody => '讀取伺服器設定失敗，請更新到最新版本或稍後再試。如果問題持續，請把下面的訊息回報給我們。';

  @override
  String get openNewsFailed => '無法開啟官網最新情報頁';
}
