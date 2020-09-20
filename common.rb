#!/usr/bin/ruby
# coding: utf-8

class String
  def ngram(n)
    c = self.split(//)
    return [self] if c.length <= n
    pos_end = c.length - n
    ret = []
    for i in 0..pos_end do
      ret.push(c[i..i+n-1].join)
    end
    return ret
  end
end

require "csv"

class NgramIndex
  # Note:
  # インデクスファイルのファイル名は決め打ち
  # データソースのファイルもこのファイル名でカレントディレクトリにおかれてることを前提とする
  Source = "KEN_ALL.CSV"
  IndexFile = "address.idx"

  Zip_col = 2
  Addr1_col = 6
  Addr2_col = 7
  Addr3_col = 8

  def initialize
    # 住所エントリのリストは @index[:addresses]に配列として格納
    # ngram インデクスそれ自体は @index[:index] に格納される。
    # ngramインデクスの各エントリは該当するngramの文字列に対応する住所を含んでいる住所エントリの
    # @index[:addresses]配列の添字の配列を持っている。
    # 例えば
    #
    # @index[:addresses] = [["0101642","秋田県","秋田市","新屋渋谷町"], ["1500042","東京都","渋谷区","宇田川町"]]
    #
    # であるとするときは
    #
    # @index[:index] = {"秋田" => [0], "田県" => [0], "渋谷" => [0,1], "東京" => [1] (... 以下省略) }
    #
    # といった形で、インデクスデータのサイズを考慮して、配列の添字のみ持っている形にしてある。
    # 従って、インデクスファイルには このアドレスのリストとngramインデクスの両方を保存する必要がある。
    # (= @index 全体を保存しとかないといけない)
    @index = {addresses: [], index: {}}
  end

  def load
    file = File.open(IndexFile, "r")
    @index = Marshal.load(file)
    file.close
  end


  def dump
    p @index
  end

  def save
    file = File.open(IndexFile, "w")
    Marshal.dump(@index, file)
    file.close
  end

  def _check_unbalance_paren(row)
    if row[Addr3_col].count('（') == row[Addr3_col].count('）')
      # カッコと閉じカッコの数が同じなので途中できれてない
      # そのまま row[Addr3_col] 使って ok
      @index[:addresses].push([row[Zip_col],row[Addr1_col],row[Addr2_col],row[Addr3_col]])
      return nil
    end
    return row
  end

  def create
    # CSVファイルから bi-gram の index を作成する
    # index はオンメモリのhashに持っているだけなので、別途 save method 呼んでファイルに吐き出すこと

    prev_row = nil
    CSV.foreach(Source, encoding: "Shift_JIS:UTF-8") do |row|
      # Note::
      # as is で元々のデータをそのままつっこんだら インデクスファイルがかなりでかくなって
      # しまったので、必要なデータのみにしぼる

      # 複数行にまたがっているエントリの処理
      # 参考: https://blog1.mammb.com/entry/2020/02/11/015807
      #
      # 「全角となっている町域部分の文字数が38文字を越える場合、また半角となっている
      # フリガナ部分の文字数が76文字を越える場合は、複数レコードに分割しています。」
      # (このプログラムでは全角部分しか扱ってないので、以下フリガナ部分は無視する)
      # 上記が仕様だが複数に分割される場合、必ずしも38文字できれるわけではないので
      # 文字数でのカウントでは判定できない。ほかにもいい判定基準はないが、分割される
      # ケースでは 全角カッコ が使われており、かつ分割されたケースでは 全角カッコが
      # 閉じれれる前に分割されてるので、それを判定すればいいようだ。
      #
      # 以下の処理 厳密にはカッコの数を数えて現状のアンバランス具合を追いながら
      # バランスするところまでおいかけるのが本当は正しいが、そこを厳密にチェックしようと
      # すると、場合分けが今以上に面倒なことになる。
      # カッコのネストはない(と分析されている)、複数カッコがあるところは存在するがそこは
      # 分割されてないなどを前提に 単にカッコがアンバランスであるかどうか(カッコと閉じ
      # カッコの数が異なってるか)だけで判断している

      if prev_row.nil?
        prev_row = _check_unbalance_paren(row)
      else
        # 直前処理でアンバランスなカッコが見つかってて prev_row に入ってる
        if prev_row[Zip_col] != row[Zip_col] || prev_row[Addr1_col] != row[Addr1_col] || prev_row[Addr2_col] != row[Addr2_col]
          # 行が分割されている場合、prev_rowのエントリの Zip_col, Addr1_col, Addr2_col は同じで Addr3_col のみが
          # 異なるはずなので、カッコがアンバランスだったとしても Addr3_col 以外が異なってる場合は
          # 複数行に分割されていなかった(データ上ただ単にカッコを閉じ忘れてる)ことになる。
          # それぞれを別エントリとして格納
          @index[:addresses].push([prev_row[Zip_col],prev_row[Addr1_col],prev_row[Addr2_col],prev_row[Addr3_col]])

          # row の方はカッコのアンバランスのチェックが必要
          prev_row = _check_unbalance_paren(row)
        else
          if row[Addr3_col].count('（') == row[Addr3_col].count('）')
            # ここで カッコの数があっている。直前でアンバランスだったんで、
            # 結果まだアンバランスなまま、さらに続きがあるようだ
            # prev_rowの住所を修正して(row[Addr3_col]を足して) さらに次の行へ
            prev_row[Addr3_col] = prev_row[Addr3_col]+row[Addr3_col]
          else
            # 分割はここでおしまいなので結合して格納。prev_rowをクリア
            @index[:addresses].push([row[Zip_col],row[Addr1_col],row[Addr2_col],prev_row[Addr3_col]+row[Addr3_col]])
            prev_row = nil
          end
        end
      end
    end

    @index[:addresses].each_with_index do |val, idx|
      # Note:
      # 検索対象としては漢字の住所部分 カラムで言うと 1,2,3 のみとする
      t = []
      for i in 1..3 do
        t.concat(val[i].ngram(2))
      end
      t.uniq.each do |v|
        if @index[:index].has_key?(v)
          @index[:index][v].push(idx)
        else
          @index[:index][v] = [idx]
        end
      end
    end
  end

  def search(str)
    # スペースは無視するという指示なので 単純にスペースを削除
    needle = str.gsub(/ /,'')
    ngrams = needle.ngram(2)
    ids = []
    ngrams.each do |v|
      if @index[:index].has_key?(v)
        ids.concat(@index[:index][v])
      end
    end
    ret = []
    len = @index[:addresses].length
    ids.sort.uniq.each do |id|
      # Note:
      # このケースは発生しないはずだけど address の配列の個数より
      # 大きな id が出てきたら それ以降はデータがそもそもないはずなので
      # loop ぬける
      if id >= len
        break
      end
      ret.push(@index[:addresses][id])
    end
    return ret
  end

  def search_print(str)
    search(str).each do |addr|
      puts('"'+addr.join('","')+'"')
    end
  end
end
