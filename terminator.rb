#!/usr/bin/env ruby

class Bucketeer
  def initialize
    @bucket = Hash.new { [] }
  end
  
  def add(timestamp, phrase)
    if phrase == @last_sentence
      puts "discarding: #{phrase.inspect}"
    else
      words = phrase.gsub("<br/>", "").strip.gsub(/[^a-zA-Z0-9\s]/, " ").split(" ")
      @bucket[timestamp] += words
      puts "[#{timestamp}] storing: #{phrase.inspect}"
      #@bucket[timestamp].uniq!
      @last_sentence = phrase
    end
  end
  
  def show
    @bucket.each do |timestamp, words|
      puts "#{timestamp}: #{words.inspect}"
    end
  end
  
  def significant_words
    @bucket.keys.sort.map do |timestamp|
      best_word_in(@bucket[timestamp])
    end
  end
  
  def best_word_in(words)
    words.sort_by { |w| w.length }.last
  end
end


bucket = Bucketeer.new

regexps = {
  "1second" => /begin = "(\d\d:\d\d:\d\d)\.\d\d\d".*">([^<]*)/,
  "10seconds" => /begin = "(\d\d:\d\d:\d)\d\.\d\d\d".*">([^<]*)/,
  "1minute" => /begin = "(\d\d:\d\d):\d\d\.\d\d\d".*">([^<]*)/
}

File.readlines(ARGV[0]).each do |line|
  matches = regexps[ARGV[1] || "10seconds"].match(line)
  if matches
    timestamp = matches[1]
    phrase = matches[2]
    bucket.add(timestamp, phrase)
  end
end

require 'rubygems'
require 'hpricot'
require 'open-uri'

def flickr_urls_for(word)
  doc = Hpricot(open("http://www.flickr.com/search/?q=#{word}"))
  (doc/"img.pc_img")[0..2].map { |element| element["src"] }
rescue
  nil
end

def show_flickr_images(word)
  image1, image2, image3 = flickr_urls_for(word)

  if image1
    html = <<-HTML
    <html>
    <body>
      <h1>#{word}</h1>
      <img src="#{image1}">
      <img src="#{image2}">
      <img src="#{image3}">
    </body>
    </html>
    HTML
  else
    html = <<-HTML
    <html>
    <body>
      <h1>#{word}</h1>
      No images :(
    </body>
    </html>
    HTML
  end
  filename = "images.html" 
  File.open(filename, "w") { |f| f.write html }
  `open #{filename}`
end

bucket.show