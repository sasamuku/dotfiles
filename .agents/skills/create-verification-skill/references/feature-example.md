# メモを作る

<!-- 架空のメモアプリと、架空の操作の道具 control-notes を使った例。コマンド名は対象リポジトリに実在するものに置き換える。 -->

利用者はブラウザか CLI からタイトル付きのメモを保存でき、下書きを取り消せる。保存したメモは一覧から開き直して確かめられる。

## サブ機能

- `create-open`: ブラウザの各入口から、空の編集画面を開く。
- `create-save`: タイトルと本文を保存する。
- `create-cancel`: ブラウザの下書きを捨てる。
- `create-cli`: 端末から同じ形のメモを作る。

## たどり着き方 (利用者の視点)

- ブラウザのツールバーの `New note` ボタンを押す。
- 入力欄の外にフォーカスがある状態で `n` を押す。
- 端末で `notes create --title <title> --body <body>` を実行する。

## control-notes での操作

前提:

- Notes が `http://127.0.0.1:4173` で動いている。
- `Release checklist` というタイトルのメモが無い。
- `control-notes doctor` が、想定した URL と使い捨てのデータディレクトリを返す。

- **ボタンで編集画面を開く。** `New note` を押す。`control-notes browser click --role button --name "New note"` を実行する。`Note editor` というフォームが現れ、`Title` 欄にフォーカスがある。
- **キーで編集画面を開く。** 編集画面を閉じ、ページにフォーカスを移して `n` を押す。`control-notes browser press --key "n"` を実行する。同じフォームが現れ、ページに `n` は入力されない。
- **入力する。** タイトルと本文を入れる。`control-notes browser fill --role textbox --name "Title" --value "Release checklist"` と `control-notes browser fill --role textbox --name "Body" --value "Tag and publish"` を実行する。`Save note` ボタンが押せるようになる。
- **保存する。** `Save note` を押す。`control-notes browser click --role button --name "Save note"` を実行する。`Note saved` という表示が出て、見出しが `Release checklist` になる。
- **保存を確かめる。** 一覧に戻ってメモを開き直す。`control-notes browser click --role link --name "All notes"` と `control-notes browser click --role link --name "Release checklist"` を実行する。保存したタイトルと本文が出る。
- **下書きを捨てる。** 新しいメモを開き、`Discard me` と入れて `Cancel` を押す。`control-notes browser click --role button --name "New note"`、`control-notes browser fill --role textbox --name "Title" --value "Discard me"`、`control-notes browser click --role button --name "Cancel"` を実行する。一覧に戻る。`Discard me` のリンクは無い。
- **CLI から作る。** `control-notes cli -- notes create --title "CLI note" --body "Created from terminal" --format json` を実行する。終了コードが `0` で、標準出力に新しいメモの ID とタイトルが出る。
- **証拠。** `All notes` から、保存した 2 件のメモを開き直す。`control-notes browser snapshot --aria --path artifacts/create-note/list.aria.txt` と `control-notes browser screenshot --path artifacts/create-note/list.png` を実行する。両方に `Release checklist` と `CLI note` が出ている。

## 落とし穴

- 入力欄にフォーカスがあると、`n` は新しい編集画面を開かず、文字として入力される。
- タイトルは保存時に前後の空白が削られる。入力した値ではなく、表示されたタイトルで確かめる。
- 保存の表示だけでは証拠にならない。一覧から開き直して確かめる。
- 後片付けで `Release checklist` と `CLI note` は消すが、証拠のファイルは残す。
