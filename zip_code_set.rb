require 'vcr'
require 'httparty'
require 'webmock'
require 'nokogiri'

require 'pry'

class ZipCodeSet 
  def initialize
    VCR.configure do |c|
      c.cassette_library_dir = 'data/zip_codes/vcr_cassettes'
      c.hook_into :webmock
    end
    VCR.use_cassette('zip_code_page') do
      #@page_html = HTTParty.get('http://www.dqnews.com/Charts/Monthly-Charts/SF-Chronicle-Charts/ZIPSFC.aspx')
      @page_html = HTTParty.get('http://www.urbanspoon.com/zips/6/SF-Bay-Area.html')
    end
  end
  def bay_area_codes
    parsed_doc = Nokogiri::HTML.parse @page_html
    elements = parsed_doc.css(".row .details .body a")
    zip_array = Array.new
    elements.each do |e|
      zip_array << e.children.text[0..4]
    end
    zip_array
  end
  def sql_query_string
    query_string = "("
    bay_area_codes.each do |zip|
      query_string << "'#{zip}',"
    end
    query_string = query_string.chop + ")"
  end
end

=begin
# Scripty use
bay_zip_set = ZipCodeSet.new
query = bay_zip_set.sql_query_string
binding.pry
=end

