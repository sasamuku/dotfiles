# 環境の取り違え

誤った環境への plan や apply は、人の注意ではなく設定で防ぐ。正しい環境と認証情報なら通り、取り違えたら失敗する構成にする。

## 判断の観点

- **provider で account を固定する**: `allowed_account_ids` を設定し、誤った account の認証情報を使えないようにする。
- **適用先は実行するディレクトリで決まる**: 環境ごとの root ディレクトリを持ち、どこで実行したかで適用先が決まるようにする。1 つの root で workspace や変数ファイルを切り替えて適用先を変える構成は、今どの環境にいるかを取り違えやすい。環境ごとに認証情報や権限が違うなら、workspace は隔離の仕組みとして足りない。
- **apply の権限は環境ごとに絞る**: CI の apply role は、その環境の protected branch や environment からだけ引き受けられるようにする。plan role は、読み取りと state の読み書きにとどめる。
- **環境ごとに違う値に既定値を置かない**: 既定値があると、入れ忘れても通ってしまう。必須の入力にして、無ければ失敗させる。
- **保護の設定を変更で失わない**: 削除保護、暗号化、バックアップ、`prevent_destroy` は、変更の後も残っていなければならない。

## 確かめ方の観点

- 各環境の plan が、正しい環境と認証設定では成功し、環境の取り違えや必須入力の不足では失敗すること。
- 既存資産を保つ変更では、同じ条件での plan を比べ、意図しない作り直しが無いこと。
- fmt、validate、`terraform test` (1.6 以降。`mock_provider` は 1.7 以降) は、振る舞いの確認である。モックで通っても、実アカウントの権限や接続性の証明にはならない。

## 出典

- Future Architect: [環境分離](https://future-architect.github.io/arch-guidelines/documents/forTerraform/terraform_guidelines.html#環境分離)
- HashiCorp: [Workspaces](https://developer.hashicorp.com/terraform/cli/workspaces) (When Not to Use Multiple Workspaces)
- AWS provider: [Argument Reference](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) (`allowed_account_ids`)
