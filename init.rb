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
    open_date TEXT,
    close_date TEXT,
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

table = CSV.parse(File.read('./data/company.csv'), headers: true)
q = <<~SQL
  INSERT INTO companies (id, railway_id, common_name, kana_name, official_name, short_name, url, category, status, sort_code)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
SQL
table.each do |t|
  db.execute(
    q,
    [t['company_cd'],
     t['rr_cd'],
     t['company_name'],
     t['company_name_k'],
     t['company_name_h'],
     t['company_name_r'],
     t['company_url'],
     t['company_type'],
     t['e_status'],
     t['e_sort']]
  )
end

table = CSV.parse(File.read('./data/line.csv'), headers: true)
q = <<~SQL
  INSERT INTO lines (id, company_id, common_name, kana_name, official_name, color_code, color_name, category, longitude, latitude, zoom_size, status, sort_code)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
SQL
table.each do |t|
  db.execute(
    q,
    [t['line_cd'],
     t['company_cd'],
     t['line_name'],
     t['line_name_k'],
     t['line_name_h'],
     t['line_color_t'],
     t['line_type'],
     t['lon'],
     t['lat'],
     t['zoom'],
     t['e_status'],
     t['e_sort']]
  )
end

table = CSV.parse(File.read('./data/station.csv'), headers: true)
q = <<~SQL
  INSERT INTO stations (id, group_id, common_name, kana_name, romaji_name, line_id, prefecture_id, post_code, address, longitude, latitude, open_date, close_date, status, sort_code)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
SQL
table.each do |t|
  db.execute(
    q,
    [t['station_cd'],
     t['station_g_cd'],
     t['station_name'],
     t['station_name_k'],
     t['station_name_r'],
     t['line_cd'],
     t['pref_cd'],
     t['post'],
     t['address'],
     t['lon'],
     t['lat'],
     t['open_ymd'],
     t['close_ymd'],
     t['e_status'],
     t['e_sort']]
  )
end

table = CSV.parse(File.read('./data/join.csv'), headers: true)
q = <<~SQL
  INSERT INTO connecting_stations (line_id, station_id_1, station_id_2)
  VALUES (?, ?, ?)
SQL
table.each do |t|
  db.execute(q, [t['line_cd'], t['station_cd1'], t['station_cd2']])
end
