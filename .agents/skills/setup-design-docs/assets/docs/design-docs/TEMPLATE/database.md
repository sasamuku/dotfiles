<!-- 不要ならこのファイルごと削除する。スキーマの正典は対象プロジェクトのスキーマ定義・マイグレーション。ここには DDL の写しではなく「どういう形で、なぜその形か」を実装者が迷わない粒度で書く。「（記入例）」は記入例ごと置き換える。 -->

# データベース設計

## テーブル

<!-- 新規・変更するテーブルだけ書く。列は「名前 / 型 / 制約 / 意味」。型は対象 DB の型で書く。以下の記入例は Postgres。 -->

### pages（記入例）

メモ本体。1 行 = 1 ページ。

| 列 | 型 | 制約 | 意味 |
|---|---|---|---|
| id | uuid | PK, default gen_random_uuid() | |
| title | text | NOT NULL, default '' | 空を許す（タイトル不要の低摩擦） |
| content | text | NOT NULL, default '' | Markdown 本文をそのまま保持（ポータビリティ） |
| visibility | text | NOT NULL, default 'public' | 'public' / 'private' |
| created_at | timestamptz | NOT NULL, default now() | |
| updated_at | timestamptz | NOT NULL, default now() | 保存のたびに更新 |

## インデックス・制約の意図

<!-- 「何のクエリのために張るか」を必ず添える。意図のないインデックスは書かない。 -->

- `links(target_title)` に index — バックリンク取得（target が自ページ名の links を引く）のため。（記入例）
- `links` に UNIQUE(source_page_id, target_title, kind) — 同一ページ内に同じリンクが複数回現れても 1 行に正規化するため。（記入例）

## 主要クエリ

<!-- この設計の成否を決めるクエリだけ、形がわかる粒度の SQL スケッチで書く。全クエリの列挙はしない。 -->

バックリンク（あるページに張られたリンク元の一覧）:（記入例）

```sql
SELECT p.* FROM links l
JOIN pages p ON p.id = l.source_page_id
WHERE l.target_title = :title;
```

## マイグレーション方針

<!-- 既存データへの影響がある場合のみ。新規テーブルだけなら「新規のみ、影響なし」の一行でよい。 -->
