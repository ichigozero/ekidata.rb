require 'csv'
require 'sqlite3'

DB_PATH = 'ekidata.db'.freeze

begin
  File.delete(DB_PATH)
rescue Errno::ENOENT
  # do nothing
end

db = SQLite3::Database.open(DB_PATH)
db.execute <<~SQL
  CREATE TABLE IF NOT EXISTS prefectures (
    id INTEGER NOT NULL PRIMARY KEY,
    pref_name TEXT
  )
SQL
db.execute <<~SQL
  CREATE TABLE IF NOT EXISTS companies (
    id INTEGER NOT NULL PRIMARY KEY,
    railway_id INTEGER,
    common_name TEXT,
    kana_name TEXT,
    official_name TEXT,
    short_name TEXT,
    url TEXT,
    category INTEGER,
    status INTEGER,
    sort_code INTEGER
  )
SQL
db.execute <<~SQL
  CREATE TABLE IF NOT EXISTS lines (
    id INTEGER NOT NULL PRIMARY KEY,
    company_id INTEGER,
    common_name TEXT,
    kana_name TEXT,
    official_name TEXT,
    color_code TEXT,
    color_name TEXT,
    category INTEGER,
    longitude REAL,
    latitude REAL,
    zoom_size INTEGER,
    status INTEGER,
    sort_code TEXT,
    FOREIGN KEY (company_id) REFERENCES companies(id)
  )
SQL
db.execute <<~SQL
  CREATE TABLE IF NOT EXISTS stations (
    id INTEGER NOT NULL PRIMARY KEY,
    group_id INTEGER,
    common_name TEXT,
    kana_name TEXT,
    romaji_name TEXT,
    line_id INTEGER,
    prefecture_id INTEGER,
    post_code TEXT,
    address TEXT,
    longitude REAL,
    latitude REAL,
    open_date TIMESTAMP,
    close_date TIMESTAMP,
    status INTEGER,
    sort_code INTEGER,
    FOREIGN KEY (line_id) REFERENCES lines(id),
    FOREIGN KEY (prefecture_id) REFERENCES prefectures(id)
  )
SQL
db.execute <<~SQL
  CREATE TABLE IF NOT EXISTS connecting_stations (
    line_id INTEGER NOT NULL,
    station_id_1 INTEGER NOT NULL,
    station_id_2 INTEGER NOT NULL,
    FOREIGN KEY (line_id) REFERENCES lines(id),
    FOREIGN KEY (station_id_1) REFERENCES stations(id),
    FOREIGN KEY (station_id_2) REFERENCES stations(id),
    PRIMARY KEY (line_id, station_id_1, station_id_2)
  )
SQL

table = CSV.parse(File.read('./data/pref.csv'), headers: true)
q = 'INSERT INTO prefectures (id, pref_name) VALUES (?, ?)'
table.each do |t|
  db.execute(q, [t['pref_cd'], t['pref_name']])
end
