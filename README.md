# 動作環境

動作確認は以下の環境で実施
ruby 2.7.1p83 (2020-03-31 revision a0c7c23c9c) [x86_64-linux-gnu]

# 実行方法

 * 展開したディレクトリに cd する(require "./common.rb" とか書いてる箇所があるので cd しないと動きません)
 * 移動した先のディレクトリに http://www.post.japanpost.jp/zipcode/dl/kogaki/zip/ken_all.zip を展開して出てくる KEN_ALL.CSV を置く
 * create_index.rb を実行してインデクスファイルを生成する(address.idx というファイルが生成される)
 * search.pl で検索する、検索対象は引数で指定

    例: ./search.pl 渋谷

# 仕様の曖昧さに対する追加仕様

 * 出力に関しては郵便番号と漢字の住所だという指定があるが、検索対象となるカラムの指定がないのでフリガナとか郵便番号等での検索に関してどうするべきか不明である。今回は表示対象である「都道府県名」「市区町村名」「町域名」(元データのカラムでいうと0スタートで数えて 6,7,8 番カラム)のみを検索対象とした(ので、郵便番号とかフリガナでの検索はできない)

 * 「スペースは文字として扱わない」とあるが、この表現だと例えば "あいう えお" という検索文字列が与えられた場合、スペースをのぞいて "あいうえお" という文字列として扱うべきだという指示なのか、あるいは他のなにかの処理をすべきなのか(例えばよくあるように "あいう"と"えお" の AND 検索とか)指示がない。とりあえず、スペースがあるケースは単に無視するように実装した(この例で言うと"あいう えお" は "あいうえお" として処理されて検索される)

 * 「スペースは文字として扱わない」とあるが、他の空白文字やその他各種文字に関しては特に指定がないのでそのまま処理している(例えば検索対象文字列にLF文字が含まれていればそれはLF文字として扱われる)

# その他コメント

データサイズが小さいこととか大範囲だと扱いが楽そうなのでインデクスはオンメモリでhashを作ってそれをMarshalで
dump/load するという形式にしてしまった。

 * Marshal使うのはruby以外からの読み出しが難しくなる等汎用性が低くあまり better な方法ではないと思われる。hashだしbinaryデータは入ってないのでjsonで吐く等も考えたが、ロード時の毎回のパースが重そうなのでひとまずMarshalで実装してしまった。今回はひとまず短時間で動く実装をということでこういう手法をとったのだけど、どうするのが better だろう?
 * オンメモリのhashでの検索なのでインデクスをひくこと自体は速いはずだけど、今回のように簡単なコマンドラインのツールだと開始ごとにインデクスファイルのロードが必要なのでその分の処理時間が気になるかもしれない
 * もっとデータが大きいのであればdbm使うとか、さらにデカイならDBとか他の手段に頼るだろう

# 参考文献
住所データ | http://www.post.japanpost.jp/zipcode/dl/kogaki/zip/ken_all.zip


日本郵便の郵便番号データ ken_all をどうにかする | https://blog1.mammb.com/entry/2020/02/11/015807

各カラムの仕様の説明はこれがわかりやすい/比較的新しい。問題の複数行レコードに関する説明もある。

# Copyright

2020 ISHIKAWA Mutsumi
