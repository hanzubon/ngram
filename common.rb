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

  def create
    CSV.foreach(Source, encoding: "Shift_JIS:UTF-8") do |row|
      # Note::
      # as is で元々のデータをそのままつっこんだら インデクスファイルがかなりでかくなって
      # しまったので、必要なデータのみにしぼる
      #
      @index[:addresses].push([row[Zip_col],row[Addr1_col],row[Addr2_col],row[Addr3_col]])
    end

    @index[:addresses].each_with_index do |val, idx|
      # Note:
      # 検索対象としては漢字の住所部分 カラムで言うと 1,2,3 のみとする
      t = []
      for i in 1..3 do
        t.concat(val[i].ngram(2))
      end
      ngrams = t.uniq
      ngrams.each do |v|
        if @index[:index].has_key?(v)
          @index[:index][v].push(idx)
        else
          @index[:index][v] = [idx]
        end
      end
    end
  end

  def search(str)
    needle = str.gsub(/ +/,'')
    ngrams = needle.ngram(2)
    p ngrams
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
