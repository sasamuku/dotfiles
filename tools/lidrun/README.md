# lidrun

必要なときに `on`、使い終わったら `off`。MacBook の蓋を閉じても処理を続けるため、Mac 全体のスリープを禁止する CLI。AC 接続中とバッテリー駆動中の両方で使う。

ユーザーによる実機での動作確認済み。ただし、電源条件や試験ログの詳細は記録していない。別の環境で使う場合は、蓋を開けて短時間試し、復旧を確認してから蓋閉じの確認へ進む。

## ビルドして手動でオン・オフする

macOS と Xcode Command Line Tools が必要。リポジトリのルートで実行する。

```sh
make -C tools/lidrun
./tools/lidrun/build/lidrun status
./tools/lidrun/build/lidrun on
```

on は管理者認証後にスリープ禁止を有効にして終了する。監視プロセスはバックグラウンドに残るため、コマンドを実行しなくても、ターミナルを閉じても禁止を継続する。期限は設けない。

使い終わったら解除する。

```sh
./tools/lidrun/build/lidrun off
./tools/lidrun/build/lidrun status
```

off も管理者認証を使い、復旧を確認してから終了する。復旧後の表示は `SleepDisabled=0`。他のスリープ防止アプリが使っている設定を無条件に解除しないため、lidrun の記録がない場合は変更しない。

CLI 自体を sudo で起動しない。必要な管理者操作だけを内部で sudo に渡す。自分が信頼するソースからビルドしたバイナリを使うこと。認証情報は保存せず、sudoers の例外や自動起動サービスも作らない。

## バッテリー駆動でも継続し、低残量では解除する

- AC の取り外しだけでは解除しない。
- AC なしで残量が10%以下になった場合、または電源状態を確認できない場合は、復旧して停止する。該当状態では on も拒否する。
- 安全解除後は自動で再開しない。充電などで状態を整え、必要なときに再び on にする。
- 同時起動と他のスリープ防止アプリとの併用はしない。開始時点でスリープ禁止なら、他者の設定を引き継がず拒否する。

スリープ禁止中は、Apple メニューなどの手動スリープも抑止する可能性がある。スリープさせるときは先に off にする。発熱の抑制は保証しない。机上で通気を確保し、閉じたままカバンへ入れて動かさない。

## 復旧エラー時は記録を残して再試行する

```sh
./tools/lidrun/build/lidrun off
./tools/lidrun/build/lidrun recover
./tools/lidrun/build/lidrun status
```

片方の監視プロセスが落ちた場合は、残った監視が復旧する。両方の監視を失った場合や OS の再起動・障害では、禁止設定が残る場合がある。再起動後の自動起動は行わないため、その場合は off または recover で復旧し、使用時に on をやり直す。

復旧に失敗した場合は成功扱いにせず、記録を残す。蓋を開き、エラーの原因を解消してから再試行する。記録を消してエラーを隠さない。root 所有の状態は `/private/var/db/lidrun` に保存する。バックグラウンドの診断ログは、その中の `log` に記録する。読み取りには管理者権限が必要。

バイナリを起動できない場合の最終手段は、管理者が状況を確認したうえで実行する次の操作。Mac 全体の禁止を解除し、設定の所有者は判別できない。

```sh
sudo /usr/bin/pmset disablesleep 0
/usr/bin/pmset -g
```

## 対象 Mac で蓋閉じを確認する

電源設定を変える実機試験。まず AC 接続・蓋を開いた状態で on → status → off → status を実行し、有効化と復旧を確認する。その後、外部ディスプレイを外して次を試す。

```sh
./tools/lidrun/build/lidrun on
/bin/sh -c 'i=0; while [ "$i" -lt 60 ]; do date -u; i=$((i + 1)); sleep 1; done' \
  > /tmp/lidrun-progress.log
```

1. on の成功を確認し、進捗記録中に蓋を約20秒閉じて開く。
2. 記録終了後、時刻に中断がないか確認する。
3. 同じ時間帯のスリープ履歴を照合し、off で解除する。

```sh
cat /tmp/lidrun-progress.log
/usr/bin/pmset -g log | tail -n 100
./tools/lidrun/build/lidrun off
./tools/lidrun/build/lidrun status
```

バッテリーでの確認は残量に余裕がある状態で行い、AC の取り外し後も進捗が続くことを確認する。監視プロセスの異常終了・重複起動・復旧失敗などは模擬環境でも検証する。実機結果は、機種・macOS・実施条件とともにローカルに記録する。

## 模擬テストと設計の根拠

```sh
make -C tools/lidrun test
```

テスト専用バイナリは本物の電源設定を変更しない。模擬テストの成功を、実機での蓋閉じ成功とは扱わない。

設定だけ変えて終了する方式では復旧を監視できないため、有効期間中だけ二つの監視を動かす方式を採用した。同じ禁止設定への他アプリの書き込みは所有者を判別できず、併用は非対応。

`pmset disablesleep` は対象環境の man ページに記載がなく、OS 更新・機種差による制約が残る。どの条件でも必ず蓋閉じスリープを防ぐ、復旧するといった保証はしない。

- [Apple: pmset の実装](https://github.com/apple-oss-distributions/PowerManagement/blob/main/pmset/pmset.m)
- [Apple: バックグラウンドプロセスの起動制約](https://developer.apple.com/library/archive/technotes/tn2083/_index.html)
- [Apple: idle-sleep 防止 API の制限](https://developer.apple.com/documentation/iokit/kiopmassertiontypepreventuseridlesystemsleep)
- [Amphetamine 開発元: 電源切り替えに関する制限](https://github.com/x74353/Amphetamine-Power-Protect)
