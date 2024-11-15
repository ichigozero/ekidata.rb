require 'sqlite3'
require './importer'

DB_PATH = 'ekidata.db'.freeze

begin
  File.delete(DB_PATH)
rescue Errno::ENOENT
  # do nothing
end

db = SQLite3::Database.open(DB_PATH)

[PrefectureImporter, CompanyImporter, LineImporter, StationImporter, JoinImporter].each do |i|
  i.create_table(db)
  i.import(db)
end
