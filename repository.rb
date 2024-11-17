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
    stmt1 = db.prepare('SELECT pref_cd FROM m_pref')
    stmt2 = db.prepare <<~SQL
      SELECT l.line_cd, l.line_name
      FROM m_line l
      INNER JOIN m_station s ON s.line_cd = l.line_cd
      WHERE s.pref_cd = ?
        AND l.e_status = 0
        AND l.line_cd > 10000
    SQL
    stmt1.execute.each do |row|
      pref_cd = row['pref_cd']
      stmt2.bind_param 1, pref_cd
      r = stmt2.execute.to_a

      next if r.empty?

      yield pref_cd, { line: r }
      stmt2.reset!
    end
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
end
