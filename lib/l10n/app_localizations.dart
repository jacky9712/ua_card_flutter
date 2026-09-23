import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('zh'),
  ];

  /// 語言選單上顯示的該語言自稱
  ///
  /// In zh, this message translates to:
  /// **'繁體中文'**
  String get languageName;

  /// No description provided for @navHome.
  ///
  /// In zh, this message translates to:
  /// **'首頁'**
  String get navHome;

  /// No description provided for @navDecks.
  ///
  /// In zh, this message translates to:
  /// **'牌組'**
  String get navDecks;

  /// No description provided for @navMessages.
  ///
  /// In zh, this message translates to:
  /// **'消息'**
  String get navMessages;

  /// No description provided for @navProfile.
  ///
  /// In zh, this message translates to:
  /// **'個人'**
  String get navProfile;

  /// No description provided for @fabCreate.
  ///
  /// In zh, this message translates to:
  /// **'出品'**
  String get fabCreate;

  /// No description provided for @searchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜尋卡號或卡名...'**
  String get searchHint;

  /// No description provided for @qrImport.
  ///
  /// In zh, this message translates to:
  /// **'QR導入'**
  String get qrImport;

  /// No description provided for @bannerPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'熱門活動橫幅'**
  String get bannerPlaceholder;

  /// No description provided for @actionMeta.
  ///
  /// In zh, this message translates to:
  /// **'對戰環境'**
  String get actionMeta;

  /// No description provided for @actionDeckBuilder.
  ///
  /// In zh, this message translates to:
  /// **'智能組牌'**
  String get actionDeckBuilder;

  /// No description provided for @actionMyDecks.
  ///
  /// In zh, this message translates to:
  /// **'我的牌組'**
  String get actionMyDecks;

  /// No description provided for @actionTopDecks.
  ///
  /// In zh, this message translates to:
  /// **'上位卡組'**
  String get actionTopDecks;

  /// No description provided for @actionMatchRecords.
  ///
  /// In zh, this message translates to:
  /// **'戰績紀錄'**
  String get actionMatchRecords;

  /// No description provided for @actionMeetup.
  ///
  /// In zh, this message translates to:
  /// **'約戰地點'**
  String get actionMeetup;

  /// No description provided for @metaTitle.
  ///
  /// In zh, this message translates to:
  /// **'對戰環境'**
  String get metaTitle;

  /// No description provided for @seeMore.
  ///
  /// In zh, this message translates to:
  /// **'查看更多 >'**
  String get seeMore;

  /// No description provided for @metaEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暫無對戰環境資料，下拉重新整理'**
  String get metaEmpty;

  /// No description provided for @unknownSeries.
  ///
  /// In zh, this message translates to:
  /// **'未知系列'**
  String get unknownSeries;

  /// No description provided for @guestDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'個人設定'**
  String get guestDialogTitle;

  /// No description provided for @guestDialogBody.
  ///
  /// In zh, this message translates to:
  /// **'你目前是訪客身分。可以先設定暱稱讓其他玩家認得你，或是登入/註冊正式帳號。'**
  String get guestDialogBody;

  /// No description provided for @myQrCard.
  ///
  /// In zh, this message translates to:
  /// **'我的 QR 名片'**
  String get myQrCard;

  /// No description provided for @setNickname.
  ///
  /// In zh, this message translates to:
  /// **'設定暱稱'**
  String get setNickname;

  /// No description provided for @loginOrRegister.
  ///
  /// In zh, this message translates to:
  /// **'登入/註冊'**
  String get loginOrRegister;

  /// No description provided for @memberCenter.
  ///
  /// In zh, this message translates to:
  /// **'會員中心'**
  String get memberCenter;

  /// No description provided for @accountLabel.
  ///
  /// In zh, this message translates to:
  /// **'帳號: {email}'**
  String accountLabel(String email);

  /// No description provided for @nicknameLabel.
  ///
  /// In zh, this message translates to:
  /// **'暱稱: {name}'**
  String nicknameLabel(String name);

  /// No description provided for @nicknameNotSet.
  ///
  /// In zh, this message translates to:
  /// **'（尚未設定）'**
  String get nicknameNotSet;

  /// No description provided for @editNickname.
  ///
  /// In zh, this message translates to:
  /// **'編輯暱稱'**
  String get editNickname;

  /// No description provided for @signOut.
  ///
  /// In zh, this message translates to:
  /// **'登出帳號'**
  String get signOut;

  /// No description provided for @signedOut.
  ///
  /// In zh, this message translates to:
  /// **'已成功登出'**
  String get signedOut;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'刪除'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'儲存'**
  String get save;

  /// No description provided for @done.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get done;

  /// No description provided for @note.
  ///
  /// In zh, this message translates to:
  /// **'備註'**
  String get note;

  /// No description provided for @unnamedPlayer.
  ///
  /// In zh, this message translates to:
  /// **'（未命名玩家）'**
  String get unnamedPlayer;

  /// No description provided for @unnamedDeck.
  ///
  /// In zh, this message translates to:
  /// **'未命名牌組'**
  String get unnamedDeck;

  /// No description provided for @noSavedDecks.
  ///
  /// In zh, this message translates to:
  /// **'目前沒有已存的牌組'**
  String get noSavedDecks;

  /// No description provided for @tierOptional.
  ///
  /// In zh, this message translates to:
  /// **'T 級（選填，自己評估這副牌組的強度）'**
  String get tierOptional;

  /// No description provided for @win.
  ///
  /// In zh, this message translates to:
  /// **'勝'**
  String get win;

  /// No description provided for @loss.
  ///
  /// In zh, this message translates to:
  /// **'敗'**
  String get loss;

  /// No description provided for @draw.
  ///
  /// In zh, this message translates to:
  /// **'平手'**
  String get draw;

  /// No description provided for @colorLabel.
  ///
  /// In zh, this message translates to:
  /// **'顏色'**
  String get colorLabel;

  /// No description provided for @colorRed.
  ///
  /// In zh, this message translates to:
  /// **'紅'**
  String get colorRed;

  /// No description provided for @colorBlue.
  ///
  /// In zh, this message translates to:
  /// **'藍'**
  String get colorBlue;

  /// No description provided for @colorGreen.
  ///
  /// In zh, this message translates to:
  /// **'綠'**
  String get colorGreen;

  /// No description provided for @colorYellow.
  ///
  /// In zh, this message translates to:
  /// **'黃'**
  String get colorYellow;

  /// No description provided for @colorPurple.
  ///
  /// In zh, this message translates to:
  /// **'紫'**
  String get colorPurple;

  /// No description provided for @errorWithMessage.
  ///
  /// In zh, this message translates to:
  /// **'錯誤: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @translationFailed.
  ///
  /// In zh, this message translates to:
  /// **'翻譯失敗'**
  String get translationFailed;

  /// No description provided for @showOriginal.
  ///
  /// In zh, this message translates to:
  /// **'顯示原文'**
  String get showOriginal;

  /// No description provided for @translateCardText.
  ///
  /// In zh, this message translates to:
  /// **'中文翻譯'**
  String get translateCardText;

  /// No description provided for @unknownName.
  ///
  /// In zh, this message translates to:
  /// **'未知名稱'**
  String get unknownName;

  /// No description provided for @apCost.
  ///
  /// In zh, this message translates to:
  /// **'AP 消耗'**
  String get apCost;

  /// No description provided for @effect.
  ///
  /// In zh, this message translates to:
  /// **'效果'**
  String get effect;

  /// No description provided for @trigger.
  ///
  /// In zh, this message translates to:
  /// **'觸發 (Trigger)'**
  String get trigger;

  /// No description provided for @priceTrend.
  ///
  /// In zh, this message translates to:
  /// **'價格趨勢 (JPY)'**
  String get priceTrend;

  /// No description provided for @noPriceHistory.
  ///
  /// In zh, this message translates to:
  /// **'暫無歷史價格數據'**
  String get noPriceHistory;

  /// No description provided for @recordMatchTitle.
  ///
  /// In zh, this message translates to:
  /// **'紀錄對戰結果'**
  String get recordMatchTitle;

  /// No description provided for @opponent.
  ///
  /// In zh, this message translates to:
  /// **'對手'**
  String get opponent;

  /// No description provided for @noKnownOpponents.
  ///
  /// In zh, this message translates to:
  /// **'還沒有已知對手，先掃對方的 QR 名片加一個，或直接在下面輸入名字'**
  String get noKnownOpponents;

  /// No description provided for @scanQrAddOpponent.
  ///
  /// In zh, this message translates to:
  /// **'掃 QR 新增對手'**
  String get scanQrAddOpponent;

  /// No description provided for @opponentNameHint.
  ///
  /// In zh, this message translates to:
  /// **'或者直接輸入對手名字（沒有帳號也能記）'**
  String get opponentNameHint;

  /// No description provided for @clearSelectedOpponent.
  ///
  /// In zh, this message translates to:
  /// **'取消已選的對手，改用文字輸入'**
  String get clearSelectedOpponent;

  /// No description provided for @deckUsedOptional.
  ///
  /// In zh, this message translates to:
  /// **'使用的牌組（選填）'**
  String get deckUsedOptional;

  /// No description provided for @result.
  ///
  /// In zh, this message translates to:
  /// **'結果'**
  String get result;

  /// No description provided for @noteOptional.
  ///
  /// In zh, this message translates to:
  /// **'備註（選填）'**
  String get noteOptional;

  /// No description provided for @matchNoteHint.
  ///
  /// In zh, this message translates to:
  /// **'這場對戰的心得、關鍵回合...'**
  String get matchNoteHint;

  /// No description provided for @matchRecorded.
  ///
  /// In zh, this message translates to:
  /// **'🎉 已記錄與「{name}」的對戰'**
  String matchRecorded(String name);

  /// No description provided for @saveRecord.
  ///
  /// In zh, this message translates to:
  /// **'儲存紀錄'**
  String get saveRecord;

  /// No description provided for @locationUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'無法取得目前位置，請確認定位權限已開啟'**
  String get locationUnavailable;

  /// No description provided for @locationAttached.
  ///
  /// In zh, this message translates to:
  /// **'已附上目前位置座標'**
  String get locationAttached;

  /// No description provided for @postMeetupTitle.
  ///
  /// In zh, this message translates to:
  /// **'發布約戰地點'**
  String get postMeetupTitle;

  /// No description provided for @locationName.
  ///
  /// In zh, this message translates to:
  /// **'地點名稱'**
  String get locationName;

  /// No description provided for @locationNameHint.
  ///
  /// In zh, this message translates to:
  /// **'例如：OO 桌遊店 3 樓'**
  String get locationNameHint;

  /// No description provided for @coordsAttached.
  ///
  /// In zh, this message translates to:
  /// **'已附上目前座標'**
  String get coordsAttached;

  /// No description provided for @attachCoordsOptional.
  ///
  /// In zh, this message translates to:
  /// **'附上目前位置座標（選填）'**
  String get attachCoordsOptional;

  /// No description provided for @plannedDeckOptional.
  ///
  /// In zh, this message translates to:
  /// **'打算用的牌組（選填）'**
  String get plannedDeckOptional;

  /// No description provided for @time.
  ///
  /// In zh, this message translates to:
  /// **'時間'**
  String get time;

  /// No description provided for @pickTimeOptional.
  ///
  /// In zh, this message translates to:
  /// **'選擇時間（選填）'**
  String get pickTimeOptional;

  /// No description provided for @meetupNoteHint.
  ///
  /// In zh, this message translates to:
  /// **'想約什麼牌組、幾點到幾點...'**
  String get meetupNoteHint;

  /// No description provided for @meetupPosted.
  ///
  /// In zh, this message translates to:
  /// **'🎉 約戰貼文已發布'**
  String get meetupPosted;

  /// No description provided for @publish.
  ///
  /// In zh, this message translates to:
  /// **'發布'**
  String get publish;

  /// No description provided for @saveToMyDecks.
  ///
  /// In zh, this message translates to:
  /// **'儲存至我的牌組 (完成編輯)'**
  String get saveToMyDecks;

  /// No description provided for @previewBeforeSave.
  ///
  /// In zh, this message translates to:
  /// **'儲存前預覽'**
  String get previewBeforeSave;

  /// No description provided for @costDistribution.
  ///
  /// In zh, this message translates to:
  /// **'成本分佈'**
  String get costDistribution;

  /// No description provided for @triggerDistribution.
  ///
  /// In zh, this message translates to:
  /// **'觸發分佈'**
  String get triggerDistribution;

  /// No description provided for @tabCardImages.
  ///
  /// In zh, this message translates to:
  /// **'卡片圖像'**
  String get tabCardImages;

  /// No description provided for @tabImportQr.
  ///
  /// In zh, this message translates to:
  /// **'導入 QR'**
  String get tabImportQr;

  /// No description provided for @deckImportQrTitle.
  ///
  /// In zh, this message translates to:
  /// **'牌組導入 QR Code'**
  String get deckImportQrTitle;

  /// No description provided for @deckImportQrHint.
  ///
  /// In zh, this message translates to:
  /// **'其他玩家掃描此碼即可快速導入您的牌組'**
  String get deckImportQrHint;

  /// No description provided for @totalCards.
  ///
  /// In zh, this message translates to:
  /// **'總張數'**
  String get totalCards;

  /// No description provided for @cardCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 枚'**
  String cardCount(int count);

  /// No description provided for @estimatedPrice.
  ///
  /// In zh, this message translates to:
  /// **'預估價格 (參考)'**
  String get estimatedPrice;

  /// No description provided for @energyCost.
  ///
  /// In zh, this message translates to:
  /// **'{value} 能'**
  String energyCost(String value);

  /// No description provided for @deckShareTitle.
  ///
  /// In zh, this message translates to:
  /// **'Union Arena 牌組分享'**
  String get deckShareTitle;

  /// No description provided for @totalCardsOf50.
  ///
  /// In zh, this message translates to:
  /// **'總張數: {count} / 50'**
  String totalCardsOf50(int count);

  /// No description provided for @scanToImportDeck.
  ///
  /// In zh, this message translates to:
  /// **'掃描導入牌組'**
  String get scanToImportDeck;

  /// No description provided for @generatingDeckImage.
  ///
  /// In zh, this message translates to:
  /// **'正在產生牌組圖片...'**
  String get generatingDeckImage;

  /// No description provided for @deckShareText.
  ///
  /// In zh, this message translates to:
  /// **'這是我剛用 UA Card App 組好的牌組，強吧！'**
  String get deckShareText;

  /// No description provided for @deckShareSubject.
  ///
  /// In zh, this message translates to:
  /// **'UA 牌組分享'**
  String get deckShareSubject;

  /// No description provided for @exportFailed.
  ///
  /// In zh, this message translates to:
  /// **'匯出失敗: {error}'**
  String exportFailed(String error);

  /// No description provided for @shareDurationTitle.
  ///
  /// In zh, this message translates to:
  /// **'分享多久？'**
  String get shareDurationTitle;

  /// No description provided for @durationMinutes.
  ///
  /// In zh, this message translates to:
  /// **'{count} 分鐘'**
  String durationMinutes(int count);

  /// No description provided for @durationHours.
  ///
  /// In zh, this message translates to:
  /// **'{count} 小時'**
  String durationHours(int count);

  /// No description provided for @shareFailed.
  ///
  /// In zh, this message translates to:
  /// **'分享失敗'**
  String get shareFailed;

  /// No description provided for @mobileOnly.
  ///
  /// In zh, this message translates to:
  /// **'此功能目前僅支援手機（Android / iOS）。桌面版的定位支援不穩定，先不開放。'**
  String get mobileOnly;

  /// No description provided for @sharing.
  ///
  /// In zh, this message translates to:
  /// **'分享中'**
  String get sharing;

  /// No description provided for @notSharing.
  ///
  /// In zh, this message translates to:
  /// **'目前沒有分享位置'**
  String get notSharing;

  /// No description provided for @autoStopAt.
  ///
  /// In zh, this message translates to:
  /// **'將於 {time} 自動停止'**
  String autoStopAt(String time);

  /// No description provided for @stopSharing.
  ///
  /// In zh, this message translates to:
  /// **'停止分享'**
  String get stopSharing;

  /// No description provided for @shareMyLocation.
  ///
  /// In zh, this message translates to:
  /// **'分享我的位置'**
  String get shareMyLocation;

  /// No description provided for @playersSharing.
  ///
  /// In zh, this message translates to:
  /// **'目前分享中的玩家'**
  String get playersSharing;

  /// No description provided for @noOneSharing.
  ///
  /// In zh, this message translates to:
  /// **'目前沒有其他人在分享位置'**
  String get noOneSharing;

  /// No description provided for @locationHubTitle.
  ///
  /// In zh, this message translates to:
  /// **'約戰 / 位置分享'**
  String get locationHubTitle;

  /// No description provided for @meetupPostsTab.
  ///
  /// In zh, this message translates to:
  /// **'約戰貼文'**
  String get meetupPostsTab;

  /// No description provided for @liveLocationTab.
  ///
  /// In zh, this message translates to:
  /// **'即時位置'**
  String get liveLocationTab;

  /// No description provided for @signUpSuccess.
  ///
  /// In zh, this message translates to:
  /// **'註冊成功！請檢查信箱驗證。'**
  String get signUpSuccess;

  /// No description provided for @authFailed.
  ///
  /// In zh, this message translates to:
  /// **'認證失敗'**
  String get authFailed;

  /// No description provided for @createAccount.
  ///
  /// In zh, this message translates to:
  /// **'建立新帳號'**
  String get createAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In zh, this message translates to:
  /// **'歡迎回來'**
  String get welcomeBack;

  /// No description provided for @signUpSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'加入 UA Card 隨時同步您的牌組'**
  String get signUpSubtitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'登入以同步您的雲端牌組'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In zh, this message translates to:
  /// **'電子郵件'**
  String get email;

  /// No description provided for @invalidEmail.
  ///
  /// In zh, this message translates to:
  /// **'請輸入有效的 Email'**
  String get invalidEmail;

  /// No description provided for @password.
  ///
  /// In zh, this message translates to:
  /// **'密碼'**
  String get password;

  /// No description provided for @passwordTooShort.
  ///
  /// In zh, this message translates to:
  /// **'密碼至少需要 6 位數'**
  String get passwordTooShort;

  /// No description provided for @signUpNow.
  ///
  /// In zh, this message translates to:
  /// **'立即註冊'**
  String get signUpNow;

  /// No description provided for @logIn.
  ///
  /// In zh, this message translates to:
  /// **'登入帳號'**
  String get logIn;

  /// No description provided for @haveAccount.
  ///
  /// In zh, this message translates to:
  /// **'已經有帳號了？'**
  String get haveAccount;

  /// No description provided for @noAccount.
  ///
  /// In zh, this message translates to:
  /// **'還沒有帳號嗎？'**
  String get noAccount;

  /// No description provided for @loginShort.
  ///
  /// In zh, this message translates to:
  /// **'登入'**
  String get loginShort;

  /// No description provided for @signUpShort.
  ///
  /// In zh, this message translates to:
  /// **'註冊'**
  String get signUpShort;

  /// No description provided for @noMatchRecords.
  ///
  /// In zh, this message translates to:
  /// **'還沒有任何對戰紀錄'**
  String get noMatchRecords;

  /// No description provided for @totalMatches.
  ///
  /// In zh, this message translates to:
  /// **'總場次'**
  String get totalMatches;

  /// No description provided for @winRate.
  ///
  /// In zh, this message translates to:
  /// **'勝率'**
  String get winRate;

  /// No description provided for @deckUsed.
  ///
  /// In zh, this message translates to:
  /// **'使用牌組'**
  String get deckUsed;

  /// No description provided for @playedAt.
  ///
  /// In zh, this message translates to:
  /// **'對戰時間'**
  String get playedAt;

  /// No description provided for @deleteThisRecord.
  ///
  /// In zh, this message translates to:
  /// **'刪除這筆紀錄'**
  String get deleteThisRecord;

  /// No description provided for @deleteRecordTitle.
  ///
  /// In zh, this message translates to:
  /// **'刪除對戰紀錄'**
  String get deleteRecordTitle;

  /// No description provided for @deleteRecordConfirm.
  ///
  /// In zh, this message translates to:
  /// **'確定要刪除這筆紀錄嗎？刪除後無法復原。'**
  String get deleteRecordConfirm;

  /// No description provided for @cancelMeetupTitle.
  ///
  /// In zh, this message translates to:
  /// **'取消約戰貼文'**
  String get cancelMeetupTitle;

  /// No description provided for @cancelMeetupConfirm.
  ///
  /// In zh, this message translates to:
  /// **'確定要取消「{name}」這則貼文嗎？取消後就不會再顯示。'**
  String cancelMeetupConfirm(String name);

  /// No description provided for @keep.
  ///
  /// In zh, this message translates to:
  /// **'保留'**
  String get keep;

  /// No description provided for @cancelPost.
  ///
  /// In zh, this message translates to:
  /// **'取消貼文'**
  String get cancelPost;

  /// No description provided for @sortBy.
  ///
  /// In zh, this message translates to:
  /// **'排序：'**
  String get sortBy;

  /// No description provided for @sortByTime.
  ///
  /// In zh, this message translates to:
  /// **'最近時間'**
  String get sortByTime;

  /// No description provided for @sortByDistance.
  ///
  /// In zh, this message translates to:
  /// **'最近距離'**
  String get sortByDistance;

  /// No description provided for @noMeetups.
  ///
  /// In zh, this message translates to:
  /// **'目前沒有約戰貼文'**
  String get noMeetups;

  /// No description provided for @unnamedLocation.
  ///
  /// In zh, this message translates to:
  /// **'未命名地點'**
  String get unnamedLocation;

  /// No description provided for @postedBy.
  ///
  /// In zh, this message translates to:
  /// **'發布者: {name}'**
  String postedBy(String name);

  /// No description provided for @deckWithName.
  ///
  /// In zh, this message translates to:
  /// **'牌組: {name}'**
  String deckWithName(String name);

  /// No description provided for @openMaps.
  ///
  /// In zh, this message translates to:
  /// **'開啟地圖 App'**
  String get openMaps;

  /// No description provided for @recordRelatedMatch.
  ///
  /// In zh, this message translates to:
  /// **'記錄與此相關的對戰'**
  String get recordRelatedMatch;

  /// No description provided for @metaLeaderboardTitle.
  ///
  /// In zh, this message translates to:
  /// **'對戰環境排行榜'**
  String get metaLeaderboardTitle;

  /// No description provided for @noMetaData.
  ///
  /// In zh, this message translates to:
  /// **'目前尚無環境資料'**
  String get noMetaData;

  /// No description provided for @metaTrend.
  ///
  /// In zh, this message translates to:
  /// **'環境趨勢分析'**
  String get metaTrend;

  /// No description provided for @updatedAt.
  ///
  /// In zh, this message translates to:
  /// **'更新於: {time}'**
  String updatedAt(String time);

  /// No description provided for @totalDecks.
  ///
  /// In zh, this message translates to:
  /// **'總計牌組'**
  String get totalDecks;

  /// No description provided for @activeSeries.
  ///
  /// In zh, this message translates to:
  /// **'活躍系列'**
  String get activeSeries;

  /// No description provided for @topShare.
  ///
  /// In zh, this message translates to:
  /// **'主流占比'**
  String get topShare;

  /// No description provided for @useCount.
  ///
  /// In zh, this message translates to:
  /// **'使用次數: {count} 次'**
  String useCount(String count);

  /// No description provided for @noDecksYet.
  ///
  /// In zh, this message translates to:
  /// **'目前還沒有任何牌組，快去組一套吧！'**
  String get noDecksYet;

  /// No description provided for @confirmDelete.
  ///
  /// In zh, this message translates to:
  /// **'確認刪除'**
  String get confirmDelete;

  /// No description provided for @deleteDeckConfirm.
  ///
  /// In zh, this message translates to:
  /// **'確定要刪除「{name}」嗎？'**
  String deleteDeckConfirm(String name);

  /// No description provided for @deckDeleted.
  ///
  /// In zh, this message translates to:
  /// **'已刪除牌組 {name}'**
  String deckDeleted(String name);

  /// No description provided for @savedOnDevice.
  ///
  /// In zh, this message translates to:
  /// **'儲存於此裝置'**
  String get savedOnDevice;

  /// No description provided for @syncedToCloud.
  ///
  /// In zh, this message translates to:
  /// **'已同步至雲端'**
  String get syncedToCloud;

  /// No description provided for @notLoggedIn.
  ///
  /// In zh, this message translates to:
  /// **'尚未登入'**
  String get notLoggedIn;

  /// No description provided for @nicknameNotSetLong.
  ///
  /// In zh, this message translates to:
  /// **'（尚未設定暱稱）'**
  String get nicknameNotSetLong;

  /// No description provided for @myQrHint.
  ///
  /// In zh, this message translates to:
  /// **'讓其他玩家掃描這個 QR，就能把你加為已知對手'**
  String get myQrHint;

  /// No description provided for @nicknameExplain.
  ///
  /// In zh, this message translates to:
  /// **'掃 QR 加對手、約戰貼文、戰績紀錄都會用這個名字讓別人認出你。'**
  String get nicknameExplain;

  /// No description provided for @nicknameHint.
  ///
  /// In zh, this message translates to:
  /// **'輸入暱稱...'**
  String get nicknameHint;

  /// No description provided for @nicknameSet.
  ///
  /// In zh, this message translates to:
  /// **'暱稱已設為「{name}」'**
  String nicknameSet(String name);

  /// No description provided for @scanQrTitle.
  ///
  /// In zh, this message translates to:
  /// **'掃描 QR Code'**
  String get scanQrTitle;

  /// No description provided for @importedDeckName.
  ///
  /// In zh, this message translates to:
  /// **'掃描導入的牌組'**
  String get importedDeckName;

  /// No description provided for @deckImported.
  ///
  /// In zh, this message translates to:
  /// **'🎉 牌組導入成功！'**
  String get deckImported;

  /// No description provided for @importFailed.
  ///
  /// In zh, this message translates to:
  /// **'❌ 導入失敗，格式不正確'**
  String get importFailed;

  /// No description provided for @opponentAdded.
  ///
  /// In zh, this message translates to:
  /// **'🎉 已將「{name}」加為對手！'**
  String opponentAdded(String name);

  /// No description provided for @addOpponentFailed.
  ///
  /// In zh, this message translates to:
  /// **'新增對手失敗'**
  String get addOpponentFailed;

  /// No description provided for @scanQrHint.
  ///
  /// In zh, this message translates to:
  /// **'請對準其他玩家分享的牌組或個人 QR Code'**
  String get scanQrHint;

  /// No description provided for @uncategorized.
  ///
  /// In zh, this message translates to:
  /// **'未分類'**
  String get uncategorized;

  /// No description provided for @filter.
  ///
  /// In zh, this message translates to:
  /// **'篩選'**
  String get filter;

  /// No description provided for @clearFilters.
  ///
  /// In zh, this message translates to:
  /// **'清除篩選'**
  String get clearFilters;

  /// No description provided for @onlyMySeries.
  ///
  /// In zh, this message translates to:
  /// **'只看我的卡組系列'**
  String get onlyMySeries;

  /// No description provided for @onlyMySeriesHint.
  ///
  /// In zh, this message translates to:
  /// **'只顯示「我的牌組」頁面裡有的系列'**
  String get onlyMySeriesHint;

  /// No description provided for @series.
  ///
  /// In zh, this message translates to:
  /// **'系列'**
  String get series;

  /// No description provided for @tier.
  ///
  /// In zh, this message translates to:
  /// **'T 級'**
  String get tier;

  /// No description provided for @deckListIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'這組牌組尚未建立完整卡表'**
  String get deckListIncomplete;

  /// No description provided for @recommendedDeck.
  ///
  /// In zh, this message translates to:
  /// **'推薦牌組'**
  String get recommendedDeck;

  /// No description provided for @copyToDeckBuilder.
  ///
  /// In zh, this message translates to:
  /// **'複製到組牌編輯器'**
  String get copyToDeckBuilder;

  /// No description provided for @topDecksTitle.
  ///
  /// In zh, this message translates to:
  /// **'上位卡組推薦'**
  String get topDecksTitle;

  /// No description provided for @noRecommendedDecks.
  ///
  /// In zh, this message translates to:
  /// **'目前尚無推薦牌組'**
  String get noRecommendedDecks;

  /// No description provided for @noDecksMatchFilter.
  ///
  /// In zh, this message translates to:
  /// **'沒有符合篩選條件的牌組'**
  String get noDecksMatchFilter;

  /// No description provided for @uncategorizedSeries.
  ///
  /// In zh, this message translates to:
  /// **'未分類系列'**
  String get uncategorizedSeries;

  /// No description provided for @winRateValue.
  ///
  /// In zh, this message translates to:
  /// **'勝率 {rate}%'**
  String winRateValue(String rate);

  /// No description provided for @newDeckPreview.
  ///
  /// In zh, this message translates to:
  /// **'新牌組預覽'**
  String get newDeckPreview;

  /// No description provided for @deckBuilderMode.
  ///
  /// In zh, this message translates to:
  /// **'組牌模式'**
  String get deckBuilderMode;

  /// No description provided for @noCardsFound.
  ///
  /// In zh, this message translates to:
  /// **'找不到符合的卡片'**
  String get noCardsFound;

  /// No description provided for @currentCardCount.
  ///
  /// In zh, this message translates to:
  /// **'目前張數: {count} / 50'**
  String currentCardCount(int count);

  /// No description provided for @totalPrice.
  ///
  /// In zh, this message translates to:
  /// **'總金額: ¥ {price}'**
  String totalPrice(String price);

  /// No description provided for @previewAndSave.
  ///
  /// In zh, this message translates to:
  /// **'預覽並儲存'**
  String get previewAndSave;

  /// No description provided for @allSeries.
  ///
  /// In zh, this message translates to:
  /// **'全部系列'**
  String get allSeries;

  /// No description provided for @selectSeries.
  ///
  /// In zh, this message translates to:
  /// **'選擇系列'**
  String get selectSeries;

  /// No description provided for @selectColor.
  ///
  /// In zh, this message translates to:
  /// **'選擇顏色'**
  String get selectColor;

  /// No description provided for @allColors.
  ///
  /// In zh, this message translates to:
  /// **'全部顏色'**
  String get allColors;

  /// No description provided for @saveDeck.
  ///
  /// In zh, this message translates to:
  /// **'儲存牌組'**
  String get saveDeck;

  /// No description provided for @deckNameHint.
  ///
  /// In zh, this message translates to:
  /// **'輸入牌組名稱...'**
  String get deckNameHint;

  /// No description provided for @deckSaved.
  ///
  /// In zh, this message translates to:
  /// **'🎉 牌組「{name}」儲存成功！'**
  String deckSaved(String name);

  /// No description provided for @saveFailed.
  ///
  /// In zh, this message translates to:
  /// **'儲存失敗，請稍後再試'**
  String get saveFailed;

  /// No description provided for @confirmSave.
  ///
  /// In zh, this message translates to:
  /// **'確認儲存'**
  String get confirmSave;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
