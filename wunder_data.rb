require 'wunderground'
require 'pry'
require 'json'
require 'vcr'
require 'webmock'

# Purpose of script:
# For each zip code, download Wunderground hourly forecast data

VCR.configure do |c|
  c.cassette_library_dir = './data/api_cache'
  c.hook_into 'webmock'
end

W_CLIENT = Wunderground.new(ENV['WUNDERGROUND_KEY'])

module WundergroundReporter

  class ZipShape
    attr_reader :code
    def initialize(shape_hash)
      @code = shape_hash["properties"]["zcta5ce10"]
    end
  end

  class HourlyForecast
    attr_reader :forecast
    def initialize(zip_code)
      VCR.use_cassette("wunderground_cache_#{zip_code}") do
        @api_forecast = W_CLIENT.hourly_for(zip_code)
      end
      @forecast = minify_forecast(@api_forecast)
    end
    def minify_forecast(json)
      hourly_forecast = Array.new
      json["hourly_forecast"].each do |hf|
        hourly_forecast << { "hour" => hf["FCTTIME"]["hour"], "civil" => hf["FCTTIME"]["civil"], "sky" => hf["sky"] }
      end
      hourly_forecast
    end
  end

  def self.write_to_json_file(file_path, data)
    File.write(file_path, data.to_json)
  end

  def self.do_stuff
    shapes_json = JSON.parse(File.read("./data/shapes/sf_and_eb_shapes.geojson"))["features"]
    zip_codes = []
    shapes_json.each do |shape|
      zip_codes << ZipShape.new(shape).code
    end
    query_counter = 0
    forecast_array = Array.new
    zip_codes.each do |zip_code|
      if query_counter > 8
        p "Resting for 65 seconds (for API happiness)"
        sleep 65
        query_counter = 0
      end
      query_counter += 1
      forecast_array << { "zip_code" => zip_code, "forecast" => HourlyForecast.new(zip_code).forecast }
      p "#{query_counter} - Got data for #{zip_code}"
    end
    write_to_json_file("./data/weather_data.json", forecast_array)
  end

end

WundergroundReporter.do_stuff
#binding.pry
