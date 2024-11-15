require 'csv'
require 'sqlite3'

class Importer
  CSV_PATH = ''.freeze
  CREATE_QUERY = ''.freeze
  INSERT_QUERY = ''.freeze

  def self.create_table(db)
    db.execute self::CREATE_QUERY
  end

  def self.import(db)
    stmt = db.prepare(self::INSERT_QUERY)
    db.transaction do
      i = 0
      CSV.foreach(self::CSV_PATH) do |row|
        i += 1
        next if i == 1

        stmt.execute(row)
      end
    end
  end
end

class PrefectureImporter < Importer
  CSV_PATH = './data/pref.csv'.freeze
  CREATE_QUERY = <<~SQL.freeze
    CREATE TABLE IF NOT EXISTS prefectures (
      id INTEGER NOT NULL PRIMARY KEY,
      pref_name TEXT
    )
  SQL
  INSERT_QUERY = 'INSERT INTO prefectures (id, pref_name) VALUES (?, ?)'.freeze
end

class CompanyImporter < Importer
  CSV_PATH = './data/company.csv'.freeze
  CREATE_QUERY = <<~SQL.freeze
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
  INSERT_QUERY = <<~SQL.freeze
    INSERT INTO companies (
      id, railway_id, common_name, kana_name, official_name,
      short_name, url, category, status, sort_code
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  SQL
end

class LineImporter < Importer
  CSV_PATH = './data/line.csv'.freeze
  CREATE_QUERY = <<~SQL.freeze
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
  INSERT_QUERY = <<~SQL.freeze
    INSERT INTO lines (
      id, company_id, common_name, kana_name, official_name,
      color_code, color_name, category, longitude, latitude,
      zoom_size, status, sort_code
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  SQL
end

class StationImporter < Importer
  CSV_PATH = './data/station.csv'.freeze
  CREATE_QUERY = <<~SQL.freeze
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
  INSERT_QUERY = <<~SQL.freeze
    INSERT INTO stations (
      id, group_id, common_name, kana_name, romaji_name,
      line_id, prefecture_id, post_code, address, longitude,
      latitude, open_date, close_date, status, sort_code
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  SQL
end

class JoinImporter < Importer
  CSV_PATH = './data/join.csv'.freeze
  CREATE_QUERY = <<~SQL.freeze
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
  INSERT_QUERY = <<~SQL.freeze
    INSERT INTO connecting_stations (line_id, station_id_1, station_id_2)
    VALUES (?, ?, ?)
  SQL
end
