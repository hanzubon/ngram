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
  Source = "KEN_ALL.CSV"
  IndexFile = "address.idx"

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
    p "saving"
    p IndexFile
    file = File.open(IndexFile, "w")
    Marshal.dump(@index, file)
    file.close
  end

  def create
    CSV.foreach(Source, encoding: "Shift_JIS:UTF-8") do |row|
      # Note::
      # 今回の課題範囲外で他のカラムを使うような拡張をあとでするようなケース(出力情報を足すとか)
      # を想定して、現状 as is で全部カラムをそのまま入れてしまってるけど入力データも
      # そこから生成されるインデクスも そこそこデカい上にインデクスの生成も検索も
      # オンメモリで処理しようとしてるので、場合によっては検索と出力には不要なカラムは
      # 削ったほうが better かもしれない
      @index[:addresses].push(row)
    end

    @index[:addresses].each_with_index do |val, idx|
      # Note:
      # 検索対象としては漢字の住所部分 カラムで言うと 6,7,8 のみとする
      # フリガナのカラムは扱わない
      t = []
      for i in 6..8 do
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

  def search
  end
end
