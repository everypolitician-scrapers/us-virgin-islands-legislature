#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'
# require 'scraped_page_archive/open-uri'

class MembersPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :members do
    noko.css('.mod-inner li a').map do |a|
      {
        name: a.text,
        url: a.attr('href'),
      }
    end
  end
end

class MemberPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :id do
    url.to_s.split('/').last.sub('senator-', '')
  end

  field :image do
    noko.css('img[src*="/Senators/"]/@src').text
  end

  field :source do
    url.to_s
  end
end

def scraper(h)
  url, klass = h.to_a.first
  klass.new(response: Scraped::Request.new(url: url).response)
end

url = 'http://www.legvi.org/index.php/senator-marvin-blyden'
data = scraper(url => MembersPage).members.map do |mem|
  scraper(mem[:url] => MemberPage).to_h.merge(name: mem[:name].sub('Senator ',''))
end
data.each { |mem| puts mem.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h } if ENV['MORPH_DEBUG']

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
ScraperWiki.save_sqlite([:id], data)
