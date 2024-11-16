require 'sqlite3'
require './importer'

DB_PATH = 'ekidata.db'.freeze

begin
  File.delete(DB_PATH)
rescue Errno::ENOENT
  # do nothing
end

db = SQLite3::Database.open(DB_PATH)

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
