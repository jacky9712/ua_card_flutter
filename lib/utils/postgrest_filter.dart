/// 把使用者輸入的搜尋字轉成可以安全塞進 PostgREST `or=(col.ilike.%值%,...)` 的值。
///
/// 分兩階段：
/// 1. 先把 LIKE 的萬用/跳脫字元 `\` `%` `_` 前面加反斜線（Postgres ILIKE 預設跳脫字元
///    是 `\`），讓使用者打的 `100%`、`a_b` 照字面比對。
/// 2. 再把 PostgREST 邏輯樹的結構字元 `,` `(` `)` `"` `*`（`*` 是 PostgREST 的 `%` 別名）
///    各換成單一個 `_`（LIKE 的單字元萬用字元）。這樣篩選字串不會被切壞，
///    `a,b` 仍然比對得到名字真的叫 `a,b` 的卡。
///
/// 順序不能反：第 2 步換進來的 `_` 要保留萬用字元的意思，所以跳脫要先做。
String escapePostgrestIlikeValue(String input) {
  final escaped = input
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
  return escaped.replaceAll(RegExp(r'[,()"*]'), '_');
}
