# 配線図

配線図は配線を変えるたびに新しい Artifact で作り、ここにリンクを足す。一番下が今の配線。

| 日付 | 内容 | 使う GPIO | スクリプト | 配線図 |
|---|---|---|---|---|
| 2026-10-27 | ブザー 2 個 | GP15, GP13 | GP15: `src/beep.rb`, `src/do.rb`, `src/so.rb`, `src/old_macdonald.rb`, `src/toccata.rb` ／ GP13: `src/do2.rb` | [ブザー 2 個の配線図](https://claude.ai/artifact/FzHFrkFKgtidkdunJsu1SE) |
| 2026-11-24 | ボタンと LED（ブザーは外した） | GP16（ボタン）, GP17（LED） | `src/button_led.rb`, `src/button_toggle.rb` | [ボタンと LED の配線図](https://claude.ai/artifact/R8XFddmm7pP4LMApdyJLRe) |
| 2026-11-24 | ボタンでブザーを鳴らす（ボタンと LED に、パッシブブザーを追加） | GP16（ボタン）, GP17（LED）, GP15（ブザー） | `src/button_buzzer.rb`, `src/doorbell.rb` | [ボタンでブザーを鳴らす配線図](https://claude.ai/artifact/YNVUE9YAVHNQwSWFp4F9NW) |
| 2026-11-24 | ミニ鍵盤（ボタン 4 個でドレミファ） | GP20, GP19, GP18, GP16（鍵盤）, GP17（LED）, GP15（ブザー） | `src/mini_keyboard.rb` | [ミニ鍵盤の配線図](https://claude.ai/artifact/7g7owas4AM2MaewdP5RCfT) |
| 2026-11-24 | かえるのうた鍵盤（ミニ鍵盤に可変抵抗を追加し、ドレミファとミファソラを切り替え） | GP26（ADC）ほか前回と同じ | `src/adc_test.rb`, `src/kaeru_keyboard.rb` | [かえるのうた鍵盤の配線図](https://claude.ai/artifact/8uC3vKGfX3AUPHmLeLYseH) |
