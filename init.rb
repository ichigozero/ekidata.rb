require 'sqlite3'
require './importer'

DB_PATH = 'ekidata.db'.freeze

begin
  File.delete(DB_PATH)
rescue Errno::ENOENT
  # do nothing
end

db = SQLite3::Database.open(DB_PATH)

[PrefectureRepository, CompanyRepository, LineRepository, StationRepository, JoinRepository].each do |r|
  rc = r.creator(db)
  rc.create
  rc.close

  ri = r.importer(db)
  ri.import
  ri.close
end
