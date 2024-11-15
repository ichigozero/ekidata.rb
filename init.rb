require 'sqlite3'
require './importer'

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
