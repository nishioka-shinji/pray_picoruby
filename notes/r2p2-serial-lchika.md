# PicoRuby (R2P2) に繋いで L チカするまで

mac に USB で挿さっている「ラズパイ」に接続したい、というところから始めて、正体の特定 → シリアル接続 → L チカ → 起動時の自動実行までを実際にやった記録。

途中でボードを無反応にしてしまったので、その原因と復旧手順も残す。ここが一番ハマりどころだった。

## 結論から

| 項目 | 値 |
|---|---|
| 正体 | Raspberry Pi 本体ではなく、PicoRuby の R2P2 シェルが動く Raspberry Pi Pico (RP2040) |
| デバイス | `/dev/cu.usbmodem*`（番号は抜き差しで変わる。後述） |
| 接続コマンド | `ls -1 /dev/cu.usbmodem*` で確認してから `tio <そのパス>`（終了は Ctrl-t → q） |
| オンボード LED | GPIO 25 |
| irb の抜け方 | `exit`（Ctrl-D は使わない） |
| 起動時の自動実行 | `/home/app.rb` に置く |
| 最大の罠 | シェルプロンプト `$>` での Ctrl-D はシェルごと落ちる |
| 詰んだ時 | 起動中に S キーで `app.rb` をスキップ。それで駄目なら BOOTSEL から焼き直し |
| 参考 | [PicoRuby 公式](https://picoruby.org/) / [R2P2 リリース](https://github.com/picoruby/R2P2/releases) |

## 1. 何が繋がっているのか調べる

まずシリアルデバイスを見る。

```
$ ls -1 /dev/cu.*
/dev/cu.Bluetooth-Incoming-Port
/dev/cu.debug-console
/dev/cu.usbmodem12301
```

`usbmodem` があるので USB CDC な何かが挿さっている。ただしこれだけでは何のボードか分からないので、USB のディスクリプタを見る。

```
$ ioreg -p IOUSB -l -w 0 | grep -iE '"(USB Product Name|USB Vendor Name|USB Serial Number)"'
...
      "USB Product Name" = "R2P2"
      "USB Vendor Name" = "PicoRuby"
      "USB Serial Number" = "E66480454F728F30"
```

ここで正体が確定する。Raspberry Pi 本体（SBC）ではなく、PicoRuby の R2P2 シェルが載った Pico 系ボードだった。

つまり「ラズパイに繋ぐ」で反射的に思い浮かぶ `ssh pi@raspberrypi.local` ではなく、USB シリアルで直接シェルに入る話になる。

なお `system_profiler SPUSBDataType` は環境によっては何も返さないことがあるので、`ioreg` の方が確実だった。

## 2. 接続する

### デバイスノードは固定ではない

先にこれを書いておく。USB を抜き差しすると番号が変わることがある。実際に一度変わった。

```
/dev/cu.usbmodem12301   →   /dev/cu.usbmodem12201
```

接続コマンドにパスを直書きして覚えていると、ある日突然 `No such file or directory` で失敗する。毎回まずこれで現在のノードを確認する。

```
ls -1 /dev/cu.usbmodem*
```

なお tio は接続が切れると `Waiting for tty device..` と表示して待ち、新しいノードが現れると自動で掴み直す。抜き差しした程度なら勝手に復帰してくれる。

```
[01:13:29.241] Disconnected
[01:13:30.264] Warning: Could not open /dev/cu.usbmodem12201 (No such file or directory)
[01:13:30.264] Waiting for tty device..
[01:13:38.294] Connected to /dev/cu.usbmodem12201
```

### 接続コマンド

macOS には `screen` と `cu` が標準で入っているが、`tio` が一番扱いやすい。

```
tio /dev/cu.usbmodem12201
```

`screen` を使う場合はこう。

```
screen /dev/cu.usbmodem12201 115200
```

USB CDC なのでボーレートの値は実質無視される。`115200` は形式的に置いているだけ。

### 抜け方が分からなくなりがちなので先に書いておく

| ツール | 終了 |
|---|---|
| tio | Ctrl-t → q |
| screen | Ctrl-a → k → y |

tio のキー一覧は `man tio` に載っている。セッション中は Ctrl-t → ? でも出る。

```
$ man tio | col -b | grep -iE "^\s+ctrl-t"
       ctrl-t ?        List available key commands
       ctrl-t b        Send serial break
       ...
       ctrl-t q        Quit
```

この抜けキーは tio 自身が処理するので、ボード側が無反応でも効く。後述のフリーズ時に効いてくる。

## 3. R2P2 のシェル

接続すると DTR でボードがリセットされるらしく、毎回起動ログが頭から流れる。

```
.............
Loading /etc/init.d/r2p2...
No app.(mrb|rb) found
Starting shell...

$>
```

`No app.(mrb|rb) found` は、自動実行するアプリが置かれていない状態。ここに `app.rb` を置けば電源投入だけで走るはずだが、置き場所のパスは未確認（後述）。

## 4. 罠その1 — `$>` での Ctrl-D はシェルを落とす

これで一度ボードを無反応にした。

`$>` プロンプトで Ctrl-D を送るとこうなる。

```
^D
Abort (RuntimeError)
```

以降、Ctrl-C を送っても Enter を送っても一切応答が返らない。

厄介なのは、USB デバイスとしては生きたままだという点。`ls /dev/cu.*` にも `ioreg` にも出続けるので、「繋がっているのに無反応」という判断に迷う状態になる。

```
$ ls -1 /dev/cu.usbmodem*
/dev/cu.usbmodem12301          ← 列挙は残っている
```

復旧は USB の抜き差しか、ボードのリセット。ソフト側からは戻せなかった。

### tio がポートを掴んだままになる

フリーズした tio を放置すると、ポートを掴んだままなので他から触れない。`lsof` で確認できる。

```
$ lsof /dev/cu.usbmodem12301
COMMAND   PID           USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
tio     42555 nishiokashinji    5u   CHR    9,7      0t9 1333 /dev/cu.usbmodem12301
```

Ctrl-t → q で抜けるのが正道。効かなければ `kill <PID>` で落とす。SIGTERM で素直に終わった。

## 5. 罠その2 — スクリプトから叩くなら端末問い合わせに応答が要る

`tio` を介さず、自前スクリプトでシリアルを読み書きしようとすると固まることがある。原因は R2P2 のシェルがカーソル位置を問い合わせてくるため。

生のバイト列を見るとこうなっている。

```
b'\r\n\x1b[?25l\x1b[1G\x1b[6n'
```

末尾の `ESC[6n` は DSR (Device Status Report) のカーソル位置問い合わせ。端末側が `ESC[<row>;<col>R` を返すまでシェルが待つので、無言でいると先に進まない。

スクリプトから叩くなら、読み取りループの中で自動応答させる。

```python
if b'\x1b[6n' in chunk:
    os.write(fd, b'\x1b[24;80R')   # カーソル位置の返答
if b'\x1b[5n' in chunk:
    os.write(fd, b'\x1b[0n')       # ステータス OK の返答
```

`tio` や `screen` 越しに人間が打つ分には端末が勝手に応答するので、この問題は起きない。自動化しようとした時だけ踏む。

## 6. L チカ

`$>` から irb に入る。

```
$> irb
irb>
```

以下、実際のセッション。

```ruby
irb> require 'gpio'
=> false
irb> led = GPIO.new(25, GPIO::OUT)
=> #<GPIO:20005e9c>
irb> led.write(1)
=> 0
irb> led.write(0)
=> 0
```

読み方のメモ。

- `require 'gpio'` の `=> false` はエラーではない。R2P2 側で既にロード済みで「新たに読み込まなかった」という意味。`true` を期待していると誤解しやすい。
- `GPIO.new` がオブジェクトを返していれば、ピンの確保と出力方向の設定は成功している。
- `write` の戻り値 `0` は成功。

点滅は 1 行にまとめる。irb は 1 行ずつ評価するので、複数行のブロックは書きづらい。

```ruby
irb> 10.times { led.write(1); sleep_ms 250; led.write(0); sleep_ms 250 }
=> 10
```

`sleep_ms` と、秒指定の `sleep` の両方が使えた。

```ruby
irb> 10.times { led.write(1); sleep 0.25; led.write(0); sleep 0.25 }
=> 10
```

どちらも 250ms 間隔で 10 回点滅することを目視で確認した。

### 戻り値だけで成功と判断しない

`=> 10` は「例外を出さずに 10 回ループした」ことしか意味しない。ピン番号を間違えていても同じ戻り値が返る。L チカは目視確認が必須。

### ボードによって LED の場所が違う

| ボード | オンボード LED |
|---|---|
| Pico / Pico 2 | GPIO 25。上記コードで光る |
| Pico W / Pico 2 W | 無線チップ (CYW43) 側に繋がっており、GPIO 25 では光らない |

今回は Pico / Pico 2 だったので GPIO 25 で通った。W 系だと同じコードが無言で空振りする。

## irb を抜ける

`exit` で `$>` に戻れる。

```
$> irb
irb> exit
$>
```

Ctrl-D は使わないこと。irb の中ならどうなるか未検証だが、1 つ下の階層である `$>` では前述の通りシェルごと落ちる。押し間違えた時の代償が大きいので、`exit` に統一しておくのが安全。

抜け方を階層で整理するとこうなる。

| 階層 | 抜ける操作 | 戻り先 |
|---|---|---|
| irb | `exit` | R2P2 シェル (`$>`) |
| R2P2 シェル | 抜ける概念はない。tio 側を終了する | - |
| tio | Ctrl-t → q | mac のターミナル |

## 起動時に自動実行させる

### 置き場所を特定する

起動ログの `No app.(mrb|rb) found` がどこを探した結果なのかは、init スクリプトを見れば分かる。ただし `cat` するとこうなる。

```
$> cat /etc/init.d/r2p2
RITE0300HSMK0000IREP...(化ける)...
```

テキストではなくコンパイル済みの mruby バイトコードだから。冒頭の `RITE0300` が mruby バイトコードのマジックナンバー。

それでも文字列テーブルはそのまま読めるので、必要な情報は取り出せる。化けた出力の中にこれらが並んでいた。

```
HOM(E)  /app.mrb   Loading app.mrb
        /app.rb    Loading app.rb
                   No app.(mrb|rb) found
```

`HOME` に `/app.mrb` を繋いだパスをまず探し、無ければ `/app.rb` を探す、という順序と読める。`pwd` が `/home` を返すので `HOME` は `/home`。したがって置き場所は `/home/app.rb`。

バイナリを `cat` して化けても、文字列テーブルは読めることがある。捨てずに眺める価値はある。

同じ文字列テーブルに `gpio` も入っていた。起動時に gpio をロードしているので、irb で `require 'gpio'` が `=> false` を返す理由もこれで説明がつく。

### 無限ループにしてもよい。ただし S キーを覚えておくこと

init は `app.rb` をロードした後にシェルを起動する。`app.rb` が返ってこなければシェルは起動しない。

一見これは詰みに見えるが、退路が用意されている。公式のトラブルシューティングにこうある。

> Lost Control After app.rb Deployment — At startup of R2P2, pressing 'S' key will skip running the app.rb

起動時に S キーを押すと `app.rb` の実行をスキップしてシェルに入れる。したがって `while true` で書いても復旧できる。

これを知らずに「無限ループは詰む」と思い込むと、遠回りをすることになる。実際にした。

常時点滅させたいなら、素直にこう書けばいい。シェルが要る時だけ起動時に S を押す。

```ruby
require 'gpio'
led = GPIO.new(25, GPIO::OUT)
while true
  led.write(1); sleep_ms 500
  led.write(0); sleep_ms 500
end
```

ただし点滅中はシェルが使えない。点滅とシェルを同時に成立させたければ別の仕組みが要るが、次節のとおり Task は使えなかった。

### ファイルを書く

`/bin` にマスストレージ化のコマンドは無かった。ボード上で書くことになる。

```
$> ls /bin
cat  date  free  hello  install  irb  ls  mkdir  mv
nmble  nmcli  rapicco  rm  setup_rtc  setup_sdcard
taskstat  touch  vim  wifi_connect
```

`vim` はあるが、シリアル越しの vim は面倒なので irb から書く方が楽。1 行ずつ戻り値を確認できる。

```ruby
$> irb
irb> f = File.open("/home/app.rb", "w")
=> #<File:2001b384>
irb> f.write("require 'gpio'\n")
=> 15
irb> f.write("led = GPIO.new(25, GPIO::OUT)\n")
=> 30
irb> f.write("10.times { led.write(1); sleep_ms 250; led.write(0); sleep_ms 250 }\n")
=> 68
irb> f.close
=> nil
irb> exit
```

`write` の戻り値は書き込んだバイト数。文字列の長さと一致していれば途中で切れていない。ここでは 15 / 30 / 68 で一致していた。

書けたら確認する。

```
$> cat /home/app.rb
require 'gpio'
led = GPIO.new(25, GPIO::OUT)
10.times { led.write(1); sleep_ms 250; led.write(0); sleep_ms 250 }
```

### 再起動して確認

USB を抜き差しする。接続時に DTR でリセットがかかるので、起動ログが頭から流れる。

```
Loading /etc/init.d/r2p2...
Loading app.rb          ← 以前は No app.(mrb|rb) found
Starting shell...

$>
```

`Loading app.rb` に変わり、LED が 10 回点滅してから `$>` が出れば成功。点滅に 5 秒かかるので、シェルが出るまで少し待たされる。

## Task による並行実行は動かなかった

点滅とシェルを両立させるため、`Task` で点滅を別タスクに逃がすことを試みた。結論から言うと、この firmware では動かない。

API 自体は存在する。[公式リファレンス](https://picoruby.org/Task.html) によれば `Task.new(name:, priority:) { ... }` で生成し、インスタンスメソッドの `run` で開始する。`list` `get` `pass` `suspend` `resume` `terminate` `join` も定義されている。

実際に試した結果。

| 経路 | 結果 |
|---|---|
| irb から直接 `led.write` | 光る |
| `app.rb` に直接ループを書く | 光る |
| irb から `Task.new` + `t.run` | 例外は出ず即座に返るが、ブロックが実行されない |
| irb から `t.status` | フリーズする |
| `app.rb` から `Task.new` + `t.run` | クラッシュしてブートループに入る |

`Task.new` も `t.run` も `#<Task:...>` を返すので成功したように見えるが、ブロックは走らない。ブロック内で GPIO を作り直してクロージャを回避しても変わらなかった。`sleep 5` で明示的に制御を手放しても走らない。

`t.status` はフリーズを引き起こすので触らないこと。

そして `app.rb` の文脈で `Task` を使うと、ハングではなくクラッシュする。USB の列挙と切断を繰り返すブートループになり、mac 側からはデバイスが現れたり消えたりして見える。

```
[01:43:50.079] Connected to /dev/cu.usbmodem12201
.......
Loading /etc/init.d/r2p2...
Loading app.rb
                       ← ここから進まず、やがて切断
[01:44:24.943] Disconnected
```

RUBY_VERSION は `"3.4"` だった。これは PicoRuby が実装する Ruby の言語バージョンであって、R2P2 のリリース番号ではない。

## 詰んだ時の復旧

段階が 3 つある。軽い方から試す。

### 1. S キーで app.rb をスキップ

`app.rb` が原因でシェルに入れない場合は、これで足りる。起動中に S を押すだけ。シェルに入れたら `rm /home/app.rb` する。

### 2. 抜き差し

シェルが無反応になっただけなら、USB を抜き差しすれば戻る。`$>` で Ctrl-D を押してしまった場合はこれ。

tio は接続が切れると自動で掴み直すので、tio 自体を終了する必要はない。ポートを掴んだまま固まっている場合だけ、`lsof` で PID を調べて `kill` する。

### 3. BOOTSEL から firmware を焼き直す

USB に列挙すらされなくなった場合。ROM 側のブートローダで動くので、firmware が壊れていても応答する。

1. USB を抜く
2. BOOTSEL ボタンを押したまま USB を挿す
3. ボタンを離す
4. `RPI-RP2` ドライブがマウントされる

マウントされたら機種を確認する。ここを間違えると動かない firmware を焼くことになる。

```
$ cat /Volumes/RPI-RP2/INFO_UF2.TXT
UF2 Bootloader v3.0
Model: Raspberry Pi RP2
Board-ID: RPI-RP2
```

`Board-ID: RPI-RP2` なら RP2040、つまり Pico。Pico 2 なら `RP2350` になる。

firmware は [R2P2 のリリース](https://github.com/picoruby/R2P2/releases) から取る。ファイル名で機種が分かれている。

| 機種 | ファイル名のパターン |
|---|---|
| Pico (RP2040) | `R2P2-PICORUBY-*-PICO-*.uf2` |
| Pico 2 W (RP2350) | `R2P2-PICORUBY-*-PICO2_W-*.uf2` |

アセットは `.gz` と `.zip` で置かれているので展開が要る。

```
$ curl -sSL -o r2p2.uf2.gz \
    https://github.com/picoruby/R2P2/releases/download/0.5.0/R2P2-PICORUBY-PICO-0.5.0-20250912-afd73b9.uf2.gz
$ gunzip r2p2.uf2.gz
```

焼く前に中身を確認しておくと、機種違いを踏まずに済む。

```
$ xxd -l 32 r2p2.uf2
00000000: 5546 320a 5751 5d9e 0020 0000 0000 0010  UF2.WQ].. ......
00000010: 0001 0000 0000 0000 8609 0000 56ff 8be4  ............V...
```

先頭の `UF2\n` (`5546 320a`) と `0x9E5D5157` が UF2 のマジックナンバー。オフセット 0x1C の 4 バイトがファミリ ID で、リトルエンディアンで読んで `0xe48bff56` なら RP2040 向け。

あとはドライブにコピーするだけ。書き込みが終わると自動で再起動し、ドライブが消える。

```
$ cp r2p2.uf2 /Volumes/RPI-RP2/
```

なお公式には一括で取得するスクリプトも用意されている。

```
curl -fsSL https://picoruby.org/r2p2-latest.sh | sh
```

### 焼き直してもファイルシステムは残るかもしれない

UF2 を焼いた後も、フラッシュ上のファイルシステム領域が残っている可能性がある。壊れた `app.rb` が原因の場合、焼き直しただけでは直らないことがある。焼いた後もシェルに入れないなら、S キーでスキップする方を先に試す。

## 関連

- [ファイルシステムと FAT](../filesystem/fat-and-filesystems.md) — ボードのフラッシュが FAT である根拠と、`System Volume Information` や `.fseventsd` の読み方
