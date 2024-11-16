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
    CREATE TABLE IF NOT EXISTS prefectures (
      pref_cd INTEGER NOT NULL PRIMARY KEY,
      pref_name TEXT
    )
  SQL
  INSERT_QUERY = 'INSERT INTO prefectures VALUES (?, ?)'.freeze

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
    CREATE TABLE IF NOT EXISTS companies (
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
  INSERT_QUERY = 'INSERT INTO companies VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'.freeze

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
    CREATE TABLE IF NOT EXISTS lines (
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
      FOREIGN KEY (company_cd) REFERENCES companies(company_cd)
    )
  SQL
  INSERT_QUERY = <<~SQL.freeze
    INSERT INTO lines VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  SQL

  def self.creator(db)
    RepositoryCreator.new db, CREATE_QUERY
  end

  def self.importer(db)
    RepositoryImporter.new db, CSV_PATH, INSERT_QUERY
  end
end

module StationRepository
  CSV_PATH = './data/station.csv'.freeze
  CREATE_QUERY = <<~SQL.freeze
    CREATE TABLE IF NOT EXISTS stations (
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
      FOREIGN KEY (line_cd) REFERENCES lines(line_cd),
      FOREIGN KEY (pref_cd) REFERENCES prefectures(prefF_cd)
    )
  SQL
  INSERT_QUERY = <<~SQL.freeze
    INSERT INTO stations VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
    CREATE TABLE IF NOT EXISTS joins (
      line_cd INTEGER NOT NULL,
      station_cd1 INTEGER NOT NULL,
      station_cd2 INTEGER NOT NULL,
      FOREIGN KEY (line_cd) REFERENCES lines(line_cd),
      FOREIGN KEY (station_cd1) REFERENCES stations(station_cd),
      FOREIGN KEY (station_cd2) REFERENCES stations(station_cd),
      PRIMARY KEY (line_cd, station_cd1, station_cd2)
    )
  SQL
  INSERT_QUERY = <<~SQL.freeze
    INSERT INTO joins VALUES (?, ?, ?)
  SQL

  def self.creator(db)
    RepositoryCreator.new db, CREATE_QUERY
  end

  def self.importer(db)
    RepositoryImporter.new db, CSV_PATH, INSERT_QUERY
  end
end
