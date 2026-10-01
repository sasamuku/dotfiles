---
name: setup-design-docs
description: プロジェクトに ADR と Design Docs の管理雛形を導入する。テンプレート、一覧、採番・ステータス・更新ルールを整備したいときに使う。
---

# Setup Design Docs

ADR は意思決定 1 つの「決定と背景」、Design Doc は機能・開発 1 つの「目的・スコープ・設計・却下した代替案」を残す。

## 導入

1. 対象プロジェクトの指示と既存文書を確認する。配置・テンプレート・一覧がある場合は既存の運用を優先し、不足分だけ補う。移動や上書きはしない。
2. 新規導入には [assets/docs](assets/docs) を使い、次の構成を作る。導入だけの依頼なら、実際の ADR・Design Doc は作成しない。

   ```text
   docs/
   ├── adr/
   │   ├── README.md        # 目的・運用ルール・空の一覧
   │   ├── TEMPLATE.md
   │   ├── AGENTS.md        # README を参照する作業ルールの正本
   │   └── CLAUDE.md        # @AGENTS.md の1行のみ
   └── design-docs/
       ├── README.md
       ├── AGENTS.md        # 作業ルールの正本
       ├── CLAUDE.md        # @AGENTS.md の1行のみ
       └── TEMPLATE/
           ├── README.md
           ├── api.md
           ├── database.md
           └── screens.md
   ```

3. 各ディレクトリの作業ルールは `AGENTS.md` を正本とし、`CLAUDE.md` には `@AGENTS.md` の1行だけを記載する。既存の指示ファイルがある場合はその管理方法を維持し、必要なルールだけ統合する。
4. レビュー方法・文書の配置・型やスキーマの正典などを対象プロジェクトに合わせる。雛形の記入例は採用済みの設計ではない。API・DB・画面が対象外なら補助テンプレートと本体のリンクを外す。

## 引き継ぐ運用

- 採番は ADR / Design Docs それぞれの最大番号 + 1、4 桁ゼロ埋め。番号の再利用・欠番の詰め直しはしない。
- ADR は `Proposed` から始める。合意後は `Accepted`。Accepted の決定内容は変更せず、新 ADR で置き換え、旧記録を `Deprecated` / `Superseded` にする（誤字修正は可）。
- Design Doc は `Draft` → `Accepted` → `Implemented`。合意後の変更は経緯が残る追記・補足を優先し、置き換え時は `Superseded` と参照先を残す。
- 状態は実際の合意・実装状況に合わせ、導入作業だけで承認済みにはしない。新規追加・ステータス変更時は各 README の一覧も更新する。
- Design Doc の横断的な決定は ADR に切り出してリンクする。個別の実装手順・チケット分割は Issue 側に置く。

## 検証

導入先の差分で既存文書が保持されていることを確認する。README・テンプレート・指示の相対リンクと `CLAUDE.md` の `@AGENTS.md` の参照先を確認し、不要な補助資料を外した場合は参照も削除する。テンプレートのコメントと記入例は残し、記入済みの成果物では削除・置換する。
