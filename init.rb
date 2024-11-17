require 'fileutils'
require 'json'
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

LineRepository.lines_by_prefectures(db) do |pref_cd, data|
  File.open("./api/p/#{pref_cd}.json", 'w') do |f|
    f.write(JSON.pretty_generate(data))
  end
end

StationRepository.stations_by_lines(db) do |line_cd, data|
  File.open("./api/l/#{line_cd}.json", 'w') do |f|
    f.write(JSON.pretty_generate(data))
  end
end

StationRepository.station_details(db) do |station_cd, data|
  File.open("./api/s/#{station_cd}.json", 'w') do |f|

StationRepository.stations_by_groups(db) do |station_cd, data|
  File.open("./api/g/#{station_cd}.json", 'w') do |f|

JoinRepository.station_joins_by_lines(db) do |line_cd, data|
  File.open("./api/n/#{line_cd}.json", 'w') do |f|
    f.write(JSON.pretty_generate(data))
  end
end
