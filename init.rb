require 'csv'
require 'fileutils'
require 'json'
require 'sqlite3'
require './repository'
require './xml'

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

records = lambda do |path, &block|
  CSV.foreach(path, encoding: 'UTF-8').with_index(&block)
end

[
  PrefectureRepository.importer(db),
  CompanyRepository.importer(db),
  LineRepository.importer(db),
  StationRepository.importer(db),
  JoinRepository.importer(db)
].each do |r|
  r.do records
  r.close
end

db.results_as_hash = true

LineRepository.lines_by_prefectures(db) do |pref, data|
  pref_cd = pref['pref_cd']
  builder = XMLBuilder.lines_by_prefectures(pref, data)

  File.open("./api/p/#{pref_cd}.xml", 'w') do |f|
    f << builder.to_xml
  end

  File.open("./api/p/#{pref_cd}.json", 'w') do |f|
    f.write(JSON.pretty_generate({ line: data }))
  end
end

StationRepository.stations_by_lines(db) do |line, data|
  line_cd = line['line_cd']
  builder = XMLBuilder.stations_by_lines(line, data)

  File.open("./api/l/#{line_cd}.xml", 'w') do |f|
    f << builder.to_xml
  end

  File.open("./api/l/#{line_cd}.json", 'w') do |f|
    f.write(JSON.pretty_generate({ station_l: data }))
  end
end

StationRepository.station_details(db) do |station_cd, data|
  builder = XMLBuilder.station_details data

  File.open("./api/s/#{station_cd}.xml", 'w') do |f|
    f << builder.to_xml
  end

  File.open("./api/s/#{station_cd}.json", 'w') do |f|
    f.write(JSON.pretty_generate({ station: data }))
  end
end

StationRepository.station_groups(db) do |station, data|
  station_g_cd = station['station_g_cd']
  builder = XMLBuilder.station_groups(station, data)

  File.open("./api/g/#{station_g_cd}.xml", 'w') do |f|
    f << builder.to_xml
  end

  File.open("./api/g/#{station_g_cd}.json", 'w') do |f|
    f.write(JSON.pretty_generate({ station_g: data }))
  end
end

JoinRepository.station_joins_by_lines(db) do |line_cd, data|
  builder = XMLBuilder.joins_by_lines data

  File.open("./api/n/#{line_cd}.xml", 'w') do |f|
    f << builder.to_xml
  end

  File.open("./api/n/#{line_cd}.json", 'w') do |f|
    f.write(JSON.pretty_generate({ station_join: data }))
  end
end
