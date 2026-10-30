# UA Card

[![CI](https://github.com/jacky9712/ua_card_flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/jacky9712/ua_card_flutter/actions/workflows/ci.yml)

UNION ARENA 卡牌輔助 App，以 Flutter 開發，後端使用 Supabase。

## 功能

- **卡片圖鑑**：瀏覽、搜尋卡片，卡片詳情含市場價格走勢圖
- **組牌**：建立與編輯牌組，顯示牌組統計
- **推薦牌組／對戰環境**：資料來自另一個 Python 爬蟲 pipeline，每日更新
- **對戰紀錄**：手動記錄對戰結果與勝率統計
- **分享牌組**：產生 QR Code 或有時效的分享代碼，掃描即可導入
- **揪團與即時位置分享**
- **多語系**：繁體中文、日文、英文

## 架構

```
lib/
├── screens/       畫面（Widget）
├── viewModels/    狀態管理（Riverpod Notifier）
├── repositories/  Supabase 存取；providers.dart 統一提供，測試時可 override
├── models/
├── utils/         純邏輯（牌組統計、QR 編解碼、錯誤碼等）
├── theme/
└── l10n/          多語系 arb 與產生的程式碼
```

- **分層**：Screen → ViewModel → Repository。ViewModel 只回報 `AppErrorCode`，由畫面負責翻譯成使用者看得懂的訊息。
- **資料安全**：App 使用匿名登入，Supabase 的 Row Level Security policy 一律限定 `authenticated`；打包在 App 裡的 anon key 只有唯讀權限。
- **資料庫 migration**：放在 `supabase/migrations/`，寫成可重複執行。

## 測試

ViewModel、Repository、純邏輯與 Widget 都有測試。Repository 透過 Riverpod provider override 換成假物件，測試不需要連線 Supabase。另有測試檢查三個語系的 arb key 是否一致。

每次 push 與 PR 都會由 GitHub Actions 執行 `flutter analyze` 與 `flutter test`。

## 本機執行

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

`assets/env.txt` 未納入版本控制，執行前請自行建立：

```
SUPABASE_URL=<your Supabase project URL>
SUPABASE_ANON_KEY=<your anon key>
```
