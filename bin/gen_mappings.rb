#!/usr/bin/env ruby

require 'bundler/setup'
require 'httparty'
require 'nokogiri'
require 'securerandom'
require 'pry'

def uri(page: 1)
  "https://www1.interactivebrokers.com/en/index.php?f=2222&exch=amex&showcategories=STK&p=&cc=&limit=100&page=#{page}"
end

response = HTTParty.get(uri)

doc = Nokogiri::HTML response
max_value_element = doc.search('.pagination li')[-2]
pages = max_value_element.children.last.text.to_i

raise('Element with the latest page number not found, looks like IB layout changed') if pages.zero?

tickers = pages.times.each_with_object({}) do |n, acc|
  puts "===> Scraping page #{n+1} of #{pages}"
  page = Nokogiri::HTML HTTParty.get uri(page: n + 1)

  table = page.search('.container table').find { |t| t.css('tr[1] > th').first.text.downcase == "ib symbol" }
  table.css('tbody > tr').each do |tr|
    cells = tr.css('td')

    ticker = cells.first.text.gsub(' ', '.')
    conid = cells[1].children.first.attributes['href'].value.match(/conid=(\d+)/)[1]

    acc[ticker] = conid
  rescue
    puts "something went wrong with: #{cells}"
    next
  end
end

# At this point we have everything we need, so we the goal is just re-create the symbolsMaps.xml

puts "===> Building xml"
builder = Nokogiri::XML::Builder.new(:encoding => 'utf-8') do |xml|
  xml.settings "Version": '1.3' do |xml|
    tickers.each do |ticker, conid|
      xml.Item do |xml|
        xml.Name("symbolMap")
        xml.Type("SettingItemGroup")
        xml.Item do |xml|
          xml.Name("id")
          xml.Type("SettingItemString")
          xml.Value(SecureRandom.uuid)
        end

        xml.Item do |xml|
          xml.Name("tradableSymbol")
          xml.Type("SettingItemSymbol")
          xml.BusinessObjectInfo do |xml|
            xml.Id("#{conid}@STK@@SMART")
            xml.ConnectionId("Interactive Brokers-Interactive Brokers-Default-Interactive Brokers")
            xml.Name(ticker)
          end
        end

        %w[quotesSymbol tickHistorySymbol minuteHistorySymbol dayHistorySymbol].each do |name|
          xml.Item do |xml|
            xml.Name(name)
            xml.Type("SettingItemSymbol")
            xml.BusinessObjectInfo do |xml|
              xml.Id(ticker)
              xml.ConnectionId("IQFeed-IQFeed-Default-IQFeed")
              xml.Name(ticker)
            end
          end
        end
      end
    end
  end
end

File.open('symbolsMaps.xml', 'w') {|f| f.puts builder.to_xml }
puts '===> symbolsMaps.xml created'