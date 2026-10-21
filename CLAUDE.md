Guidance for AI coding agents working in this repository.

## Project Facts

- **What this is:** UNION ARENA 卡牌輔助 App（卡片圖鑑、組牌、推薦牌組、對戰環境、
  手動對戰紀錄、揪團、即時位置分享、QR 交換牌組/加對手）。與 `ua_card_game`
  （線上對戰）共用同一個 Supabase 專案（`navppyitnnarepjixcxb`）。
- **Stack:** Flutter (Dart) + Riverpod，Supabase（Postgres + Auth，App 用匿名登入），
  多語系 zh/ja/en（`lib/l10n/*.arb` → `flutter gen-l10n`）。
- **Layout:** `lib/screens`（畫面）→ `lib/viewModels`（Riverpod Notifier）→
  `lib/repositories`（Supabase 存取，`providers.dart` 統一提供，可在測試 override）。
  `lib/utils/app_error.dart`：ViewModel 只回報 `AppErrorCode`，由畫面翻譯。
  `lib/theme/app_theme.dart`：顏色用 `AppColors`。
- **推薦牌組資料**來自 `ua_card_py` 爬蟲，不是 seed SQL；anon key 是唯讀。

### Commands (definition of done)

```bash
flutter pub get
flutter analyze
flutter test
```

`assets/env.txt` 被 gitignore，worktree 裡沒有它時 `flutter test` 會因 asset bundle
失敗——放一個假的（`SUPABASE_URL=https://example.supabase.co` /
`SUPABASE_ANON_KEY=dummy`），**絕對不要複製真的那份**。

A change is **done** only when analyze and tests are all green.

## Loop vs Ad-hoc

**Use the agentic loop** for multi-step work worth a task file:

1. `/agentic-workflow:engineering new <idea>` — draft task with goal + testable acceptance
2. `/agentic-workflow:engineering approve <id>` — queue it
3. `/agentic-workflow:engineering plan <id>` — PLAN stage writes `## Implementation Plan`, parks at the plan gate
4. `approve <id>` — BUILD → VERIFY → REVIEW runs on `feature/<id>`; review the diff, then `approve <id>` ships it as a PR

**Stay ad-hoc** for a single bounded request (rename, small fix, question).

## Conventions

- **Commits:** conventional commits `<type>: <description>`，描述用繁體中文
  （type ∈ feat, fix, refactor, docs, test, chore, perf, ci）。
- **PR：** 一律從 `main` 開分支，不要疊在別的 PR 分支上；PR 由使用者自己
  `gh pr merge <n> --merge --delete-branch` 合併，agent 不要自己 merge。
- **Supabase migration：** 新增於 `supabase/migrations/<timestamp>_<name>.sql`，
  要寫成可重複執行（`drop ... if exists` / `create or replace`）。這個專案沒有連
  Supabase CLI，合併後由使用者手動在 SQL Editor 執行——PR 說明要提醒這一步。
- **RLS：** anon key 打包在 App 裡，任何 policy 都要明確寫 `to authenticated`
  （匿名登入也算 authenticated），不能只靠 `using (...)`。
- **UI 文字** 一律走 `context.l10n`，新 key 三個 arb 都要加（有 `l10n_arb_keys_test` 檢查）。
- **await 之後** 用 `context`/`setState` 前先檢查 `mounted`；會 pop 掉自己的流程，
  在 await 前先取好 `Navigator`/`ScaffoldMessenger`/notifier。
- **Before every commit:** no hardcoded secrets; diff contains only lines that trace to the task.
