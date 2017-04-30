#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'
# require 'scraped_page_archive/open-uri'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('.mod-inner li a').each do |a|
    mp_url = URI.join url, a.attr('href')
    scrape_person(a.text, mp_url)
  end
end

def scrape_person(name, url)
  noko = noko_for(url)
  data = {
    id:     url.to_s.split('/').last.sub('senator-', ''),
    name:   name.sub('Senator ', ''),
    image:  noko.css('img[src*="/Senators/"]/@src').text,
    source: url.to_s,
  }
  data[:image] = URI.join(url, data[:image]).to_s unless data[:image].to_s.empty?
  puts data.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h if ENV['MORPH_DEBUG']
  ScraperWiki.save_sqlite([:id], data)
end

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
scrape_list('http://www.legvi.org/index.php/senator-marvin-blyden')
