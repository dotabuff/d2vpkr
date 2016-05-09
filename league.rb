#!/usr/bin/env ruby

require "rake"
require "json"
require "fileutils"

ITEMS_GAME_JSON = "dota/scripts/items/items_game.json"
LEAGUES_JSON = "dota/scripts/items/leagues.json"

begin
  output = Hash.new

  json_data = File.read(ITEMS_GAME_JSON)
  d = JSON.parse(json_data)
  d["items_game"]["items"].each do |k, v|
    if v.key?("prefab") and v["prefab"] == "league"
      league_id = v["tool"]["usage"]["league_id"] rescue next

      if league_id.to_i <= 0
        next
      end

      ticket = v["image_inventory"] rescue ""
      banner = v["image_banner"] rescue ""
      tier = v["tool"]["usage"]["tier"] rescue ""

      output[league_id] = {
        :ticket => ticket,
        :banner => banner,
        :tier => tier,
      }
    end
  end

  puts "Writing leagues to #{LEAGUES_JSON}..."
  json = JSON.pretty_generate(output)
  File.open(LEAGUES_JSON, "w") {|f| f.write(json)}
  puts "Success!"

rescue => ex
  puts "Could not find or process #{ITEMS_GAME_JSON}: #{ex}"
  exit 1
end

exit 0
