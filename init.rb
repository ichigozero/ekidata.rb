require 'fileutils'
require 'json'
require 'nokogiri'
require 'sqlite3'
require './repository'

FileUtils.mkdir_p ['./api/p', './api/l', './api/s', './api/g', './api/n']

db = SQLite3::Database.new(':memory:')

[
  PrefectureRepository.creator(db),
  CompanyRepository.creator(db),
  LineRepository.creator(db),
  StationRepository.creator(db),
  JoinRepository.creator(db)
].each do |r|
  r.do
  r.close
end

[
  PrefectureRepository.importer(db),
  CompanyRepository.importer(db),
  LineRepository.importer(db),
  StationRepository.importer(db),
  JoinRepository.importer(db)
].each do |r|
  r.do
  r.close
end

db.results_as_hash = true

LineRepository.lines_by_prefectures(db) do |pref, data|
  pref_cd = pref['pref_cd']

  builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
    xml.ekidata(version: 'ekidata.jp pref api 1.0') do
      xml.pref do
        xml.code pref_cd
        xml.name pref['pref_name']
      end
      data.each do |d|
        xml.line do
          xml.line_cd d['line_cd']
          xml.line_name d['line_name']
        end
      end
    end
  end

  File.open("./api/p/#{pref_cd}.xml", 'w') do |f|
    f << builder.to_xml
  end

  File.open("./api/p/#{pref_cd}.json", 'w') do |f|
    f.write(JSON.pretty_generate({ line: data }))
  end
end

StationRepository.stations_by_lines(db) do |line, data|
  line_cd = line['line_cd']

  builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
    xml.ekidata(version: 'ekidata.jp pref api 1.0') do
      xml.line do
        xml.line_cd line_cd
        xml.line_name line['line_name']
        xml.line_lon line ['lon']
        xml.line_lat line['lat']
        xml.line_zoom line['zoom']
      end
      data.each do |d|
        xml.station do
          xml.station_cd d['station_cd']
          xml.station_g_cd d['station_g_cd']
          xml.station_name d['station_name']
          xml.lon d['lon']
          xml.lat d['lat']
        end
      end
    end
  end

  File.open("./api/l/#{line_cd}.xml", 'w') do |f|
    f << builder.to_xml
  end

  File.open("./api/l/#{line_cd}.json", 'w') do |f|
    f.write(JSON.pretty_generate({ station_l: data }))
  end
end

StationRepository.station_details(db) do |station_cd, data|
  builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
    xml.ekidata(version: 'ekidata.jp pref api 1.0') do
      xml.station do
        xml.pref_cd data[:pref_cd]
        xml.line_cd data[:line_cd]
        xml.line_name data[:line_name]
        xml.station_cd data[:station_cd]
        xml.station_g_cd_ data[:station_g_cd]
        xml.station_name data[:station_name]
        xml.lon data[:lon]
        xml.lat data[:lat]
      end
    end
  end

  File.open("./api/s/#{station_cd}.xml", 'w') do |f|
    f << builder.to_xml
  end

  File.open("./api/s/#{station_cd}.json", 'w') do |f|
    f.write(JSON.pretty_generate({ station: data }))
  end
end

StationRepository.stations_by_groups(db) do |station_cd, data|
  File.open("./api/g/#{station_cd}.json", 'w') do |f|
    f.write(JSON.pretty_generate(data))
  end
end

JoinRepository.station_joins_by_lines(db) do |line_cd, data|
  File.open("./api/n/#{line_cd}.json", 'w') do |f|
    f.write(JSON.pretty_generate(data))
  end
end
