require 'csv'
require 'sqlite3'

class RepositoryCreator
  def initialize(db, create_query)
    @stmt = db.prepare(create_query)
  end

  def do
    @stmt.execute
  end

  def close
    @stmt.close
  end
end

class RepositoryImporter
  def initialize(db, csv_path, insert_query)
    @csv_path = csv_path
    @db = db
    @stmt = db.prepare(insert_query)
  end

  def do
    @db.transaction do
      i = 0
      CSV.foreach(@csv_path) do |row|
        i += 1
        next if i == 1

        @stmt.execute(row)
      end
    end
  end

  def close
    @stmt.close
  end
end

module PrefectureRepository
  CSV_PATH = './data/pref.csv'.freeze
  CREATE_QUERY = <<~SQL.freeze
    CREATE TABLE IF NOT EXISTS m_pref (
      pref_cd INTEGER NOT NULL PRIMARY KEY,
      pref_name TEXT
    )
  SQL
  INSERT_QUERY = 'INSERT INTO m_pref VALUES (?, ?)'.freeze

  def self.creator(db)
    RepositoryCreator.new db, CREATE_QUERY
  end

  def self.importer(db)
    RepositoryImporter.new db, CSV_PATH, INSERT_QUERY
  end
end

module CompanyRepository
  CSV_PATH = './data/company.csv'.freeze
  CREATE_QUERY = <<~SQL.freeze
    CREATE TABLE IF NOT EXISTS m_company (
      company_cd INTEGER NOT NULL PRIMARY KEY,
      rr_cd INTEGER,
      company_name TEXT,
      company_name_k TEXT,
      company_name_h TEXT,
      company_name_r TEXT,
      company_url TEXT,
      company_type INTEGER,
      e_status INTEGER,
      e_sort INTEGER
    )
  SQL
  INSERT_QUERY = 'INSERT INTO m_company VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'.freeze

  def self.creator(db)
    RepositoryCreator.new db, CREATE_QUERY
  end

  def self.importer(db)
    RepositoryImporter.new db, CSV_PATH, INSERT_QUERY
  end
end

module LineRepository
  CSV_PATH = './data/line.csv'.freeze
  CREATE_QUERY = <<~SQL.freeze
    CREATE TABLE IF NOT EXISTS m_line (
      line_cd INTEGER NOT NULL PRIMARY KEY,
      company_cd INTEGER,
      line_name TEXT,
      line_name_k TEXT,
      line_name_h TEXT,
      line_color_c TEXT,
      line_color_t TEXT,
      line_type INTEGER,
      lon REAL,
      lat REAL,
      zoom INTEGER,
      e_status INTEGER,
      e_sort TEXT,
      FOREIGN KEY (company_cd) REFERENCES m_company(company_cd)
    )
  SQL
  INSERT_QUERY = <<~SQL.freeze
    INSERT INTO m_line VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  SQL

  def self.creator(db)
    RepositoryCreator.new db, CREATE_QUERY
  end

  def self.importer(db)
    RepositoryImporter.new db, CSV_PATH, INSERT_QUERY
  end

  def self.lines_by_prefectures(db)
    stmt1 = db.prepare 'SELECT pref_cd, pref_name FROM m_pref'
    stmt2 = db.prepare <<~SQL
      SELECT l.line_cd, l.line_name
      FROM m_line l
      INNER JOIN m_station s ON s.line_cd = l.line_cd
      WHERE s.pref_cd = ?
        AND l.e_status = 0
        AND l.line_cd > 10000
      GROUP BY l.line_cd
    SQL

    stmt1.execute.each do |row|
      stmt2.bind_param 1, row['pref_cd']
      r = stmt2.execute.to_a

      yield row, r unless r.empty?

      stmt2.reset!
    end

    stmt1.close
    stmt2.close
  end
end

module StationRepository
  CSV_PATH = './data/station.csv'.freeze
  CREATE_QUERY = <<~SQL.freeze
    CREATE TABLE IF NOT EXISTS m_station (
      station_cd INTEGER NOT NULL PRIMARY KEY,
      station_g_cd INTEGER,
      station_name TEXT,
      station_name_k TEXT,
      station_name_r TEXT,
      line_cd INTEGER,
      pref_cd INTEGER,
      post TEXT,
      address TEXT,
      lon REAL,
      lat REAL,
      open_ymd TEXT,
      close_ymd TEXT,
      e_status INTEGER,
      e_sort INTEGER,
      FOREIGN KEY (line_cd) REFERENCES m_line(line_cd),
      FOREIGN KEY (pref_cd) REFERENCES m_pref(prefF_cd)
    )
  SQL
  INSERT_QUERY = <<~SQL.freeze
    INSERT INTO m_station VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  SQL

  def self.creator(db)
    RepositoryCreator.new db, CREATE_QUERY
  end

  def self.importer(db)
    RepositoryImporter.new db, CSV_PATH, INSERT_QUERY
  end

  def self.stations_by_lines(db)
    stmt1 = db.prepare 'SELECT line_cd, line_name, lon, lat, zoom FROM m_line'
    stmt2 = db.prepare <<~SQL
      SELECT station_cd, station_g_cd, station_name, lon, lat
      FROM m_station
      WHERE e_status = 0
        AND station_cd > 1000000
        AND line_cd = ?
      ORDER BY e_sort, station_cd
    SQL

    stmt1.execute.each do |row|
      stmt2.bind_param 1, row['line_cd']
      r = stmt2.execute.to_a

      yield row, r unless r.empty?

      stmt2.reset!
    end

    stmt1.close
    stmt2.close
  end

  def self.station_details(db)
    stmt = db.prepare <<~SQL
      SELECT
        s.pref_cd, s.line_cd, l.line_name, s.station_cd,
        s.station_g_cd, s.station_name, s.lon, s.lat
      FROM m_station s
      LEFT JOIN m_line l ON l.line_cd = s.line_cd
      WHERE s.e_status = 0 AND s.station_cd > 1000000
      ORDER BY s.station_cd
    SQL

    stmt.execute.each do |row|
      s = {
        pref_cd: row['pref_cd'],
        line_cd: row['line_cd'],
        line_name: row['line_name'],
        station_cd: row['station_cd'],
        station_g_cd: row['station_g_cd'],
        station_name: row['station_name'],
        lon: row['lon'],
        lat: row['lat']
      }
      yield row['station_cd'], s
    end

    stmt.close
  end

  def self.stations_by_groups(db)
    stmt1 = db.prepare 'SELECT DISTINCT station_g_cd FROM m_station'
    stmt2 = db.prepare <<~SQL
      SELECT s.pref_cd, s.line_cd, l.line_name, s.station_cd, s.station_name
      FROM m_station s
      INNER JOIN m_line l ON l.line_cd = s.line_cd
      WHERE s.e_status = 0
        AND s.station_cd > 1000000
        AND s.station_g_cd = ?
      ORDER BY s.e_sort, s.station_cd
    SQL

    stmt1.execute.each do |row|
      stmt2.bind_param 1, row['station_g_cd']
      yield row['station_g_cd'], stmt2.execute.to_a
      stmt2.reset!
    end

    stmt1.close
    stmt2.close
  end
end

module JoinRepository
  CSV_PATH = './data/join.csv'.freeze
  CREATE_QUERY = <<~SQL.freeze
    CREATE TABLE IF NOT EXISTS m_station_join (
      line_cd INTEGER NOT NULL,
      station_cd1 INTEGER NOT NULL,
      station_cd2 INTEGER NOT NULL,
      FOREIGN KEY (line_cd) REFERENCES m_line(line_cd),
      FOREIGN KEY (station_cd1) REFERENCES m_station(station_cd),
      FOREIGN KEY (station_cd2) REFERENCES m_station(station_cd),
      PRIMARY KEY (line_cd, station_cd1, station_cd2)
    )
  SQL
  INSERT_QUERY = <<~SQL.freeze
    INSERT INTO m_station_join VALUES (?, ?, ?)
  SQL

  def self.creator(db)
    RepositoryCreator.new db, CREATE_QUERY
  end

  def self.importer(db)
    RepositoryImporter.new db, CSV_PATH, INSERT_QUERY
  end

  def self.station_joins_by_lines(db)
    stmt1 = db.prepare 'SELECT line_cd FROM m_line'
    stmt2 = db.prepare <<~SQL
      SELECT
        j.station_cd1,
        j.station_cd2,
        s1.station_name AS station_name1,
        s2.station_name AS station_name2,
        s1.lon AS lon1,
        s1.lat AS lat1,
        s2.lon AS lon2,
        s2.lat AS lat2
      FROM m_station_join j
      INNER JOIN m_station s1 ON s1.station_cd = j.station_cd1
      INNER JOIN m_station s2 ON s2.station_Cd = j.station_cd2
      WHERE j.line_cd = ?
    SQL

    stmt1.execute.each do |row|
      stmt2.bind_param 1, row['line_cd']
      r = stmt2.execute.to_a

      yield row['line_cd'], r unless r.empty?

      stmt2.reset!
    end

    stmt1.close
    stmt2.close
  end
end
