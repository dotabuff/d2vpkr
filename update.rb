#!/usr/bin/env ruby

require "rake"
require "json"
require "fileutils"
require_relative "./vdf"

DOTA = File.expand_path(ENV["DOTA"] || "~/Steam/steamapps/common/dota 2 beta/game")
TEMP = File.expand_path(ENV["TEMP"] || "/tmp/paks")

CONVERT_TO_JSON = %w[
  dota/resource/{items,dota}_*.txt
  dota/scripts/items/items_game.txt
  dota/scripts/{regions,emoticons}.txt
  dota/scripts/npc/{npc_abilities,npc_heroes,npc_units,items,activelist}.txt
]

VDF_PATCHES = {
  "Lee \"Kyxy\" Kang Yang" => "Lee 'Kyxy' Kang Yang",
}

# Converts "bad" encodings to UTF-8 with unix line termination
def convert_encoding(path)
  type = `file #{path}`

  case type
  when /UTF-16/, /illegal byte sequence/
    puts "converting #{path} to utf8..."
    `iconv -f UTF-16 -t UTF-8 "#{path}" > "#{path}.tmp"`
    `mv "#{path}.tmp" "#{path}"`
  end

  if type =~ /with CRLF(, CR)? line terminators/
    sh("dos2unix", "-q", path)
  end
end

# Converts a .txt file to a separate .json file
def convert_json(path)
  dst = path.gsub(".txt", ".json")

  contents = IO.read(path)
  VDF_PATCHES.each do |re, repl|
    contents.gsub!(re, repl)
  end

  vdf = VDF.new(contents)
  json = JSON.pretty_generate(vdf.kvs)
  File.open(dst, "w") {|f| f.write(json) }
rescue => ex
  puts "Unable to convert #{path} to JSON: #{ex}"
end

# Copies a file from a source to a destination (if changed)
def copy_resource(src, dst)
  dstdir = File.dirname(dst)
  sh("mkdir", "-p", dstdir) unless Dir.exist?(dstdir)
  sh("cp", "-a", src, dst)
  convert_encoding(dst)
end

# Extracts the contents of a VPK file to a temp directory
def extract_vpk(src)
  vpkname = File.basename(src.gsub("#{DOTA}/", "").tr("/", "_"), "_dir.vpk")
  tmppath = "#{TEMP}/#{vpkname}"
  sh("mkdir", "-p", tmppath)
  sh("./d2vpk", src, tmppath, "+.vdf", "+.res", "+.txt", "+.png")
end

# Extract VPK files
Dir.glob("#{DOTA}/**/*_dir.vpk") do |path|
  extract_vpk(path)
end

# Copy non-VPK resources
Dir.glob("#{DOTA}/dota/**/*.{vdf,res,txt,png}") do |src|
  copy_resource(src, src.gsub("#{DOTA}/", ""))
end

# Copy VPK resources
Dir.glob("#{TEMP}/**/*.{vdf,res,txt,png}") do |src|
  next if src =~ /econ|hud_skins|core_pak01/
  # copy_resource(src, src.gsub("#{TEMP}/", "").gsub("_pak01", ""))
end

# Convert given resources to JSON
CONVERT_TO_JSON.each do |pattern|
  Dir.glob(pattern).each do |src|
    convert_json(src)
  end
end

exit 0
