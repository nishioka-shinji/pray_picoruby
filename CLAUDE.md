# pray_picoruby

## 記録の置き場

- 日報: `daily-reports/`
- 知見: `notes/`

## テスト

- スクリプトは `src/` に置き、Pico の `/home/` にコピーする（`cp src/<name>.rb /Volumes/R2P2/home/<name>.rb`）
- 実行はユーザーが tio で接続し、`$>` から `./<name>.rb` で行う。USB の抜き差しで `app.rb` を自動実行させてテストしない
- 例外が起きてもログに出ないことがあるため、LED・音などの結果はユーザーの目と耳で確認する
