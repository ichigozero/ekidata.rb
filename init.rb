require 'csv'
require 'sqlite3'

db = SQLite3::Database.open('ekidata.db')
db.execute <<~SQL
  CREATE TABLE IF NOT EXISTS prefectures (
    id INTEGER NOT NULL PRIMARY KEY,
    pref_name TEXT
  )
SQL

table = CSV.parse(File.read('./data/pref.csv'), headers: true)
q = 'INSERT INTO prefectures (id, pref_name) VALUES (?, ?)'
table.each do |t|
  db.execute(q, [t['pref_cd'], t['pref_name']])
end
