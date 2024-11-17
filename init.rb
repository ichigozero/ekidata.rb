require 'fileutils'
require 'json'
require 'sqlite3'
require './repository'

FileUtils.mkdir_p ['./api/p', './api/l']

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

LineRepository.lines_by_prefectures(db) do |pref_cd, row|
  File.open("./api/p/#{pref_cd}.json", 'w') do |f|
    f.write(JSON.pretty_generate(row))
  end
end

StationRepository.stations_by_lines(db) do |line_cd, row|
  File.open("./api/l/#{line_cd}.json", 'w') do |f|
    f.write(JSON.pretty_generate(row))
  end
end
