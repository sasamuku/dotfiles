---
name: principle-auth-design
description: 認証・認可・セッションの設計や実装が OWASP の推奨に沿っているかを確認するときに使う。
metadata:
  source: https://cheatsheetseries.owasp.org/
disable-model-invocation: true
---

# 認証・認可の設計原則

これから作る仕組みも既存の仕組みも、認証・認可・セッションの扱いが OWASP の推奨に沿っているかを確認する。検討中の設計や実装案、既存の設計資料やコード、設定を OWASP の該当箇所と照らし合わせる。

- 認証と復旧：[認証](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)・[多要素認証の復旧](https://cheatsheetseries.owasp.org/cheatsheets/Multifactor_Authentication_Cheat_Sheet.html#resetting-mfa)
- 認可：[認可を行う場所](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html#verify-that-authorization-checks-are-performed-in-the-right-location)・[リクエストごとの権限確認](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html#validate-the-permissions-on-every-request)
- セッション：[有効期限と失効](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html#session-expiration)

設計や実装が OWASP の推奨と異なる場合は、該当箇所を双方から示し、今の対策で防げる被害と残るリスクを説明する。対策が複数あるときは、それぞれの効果と、利用者や運用者にかかる負担を比べる。どの案を勧めるか、理由も伝える。要件によって勧める案が変わるときは、その条件をユーザーと相談する。
