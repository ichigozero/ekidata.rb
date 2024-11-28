# frozen_string_literal: true

require "sqlite3"

module Migrator
  class << self
    def create_tables(db)
      [
        <<~m_pref,
          CREATE TABLE IF NOT EXISTS m_pref (
            pref_cd INTEGER NOT NULL PRIMARY KEY,
            pref_name TEXT
          )
        m_pref
        <<~m_company,
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
        m_company
        <<~m_line,
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
        m_line
        <<~m_station,
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
        m_station
        <<~m_station_join,
          CREATE TABLE IF NOT EXISTS m_station_join (
            line_cd INTEGER NOT NULL,
            station_cd1 INTEGER NOT NULL,
            station_cd2 INTEGER NOT NULL,
            FOREIGN KEY (line_cd) REFERENCES m_line(line_cd),
            FOREIGN KEY (station_cd1) REFERENCES m_station(station_cd),
            FOREIGN KEY (station_cd2) REFERENCES m_station(station_cd),
            PRIMARY KEY (line_cd, station_cd1, station_cd2)
          )
        m_station_join
      ].each { |q| db.execute(q) }
    end
  end
end

class Repository
  def initialize(db, csv_path, queries)
    @db = db
    @csv_path = csv_path
    @stmts = {}
    queries.each do |k, v|
      @stmts[k] = db.prepare(v)
    end
  end

  def import(records)
    @db.transaction do
      records.call(@csv_path) do |row, i|
        next if i.zero?

        @stmts[:import].execute(row)
      end
    end
  end

  def close
    @stmts.each_value(&:close)
  end
end

class PrefectureRepository < Repository
  def initialize(db)
    csv_path = "./data/pref.csv"
    queries = {
      import: "INSERT INTO m_pref VALUES (?, ?)",
    }
    super(db, csv_path, queries)
  end
end

class CompanyRepository < Repository
  def initialize(db)
    csv_path = "./data/company.csv"
    queries = {
      import: "INSERT INTO m_company VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
    }
    super(db, csv_path, queries)
  end
end

class LineRepository < Repository
  def initialize(db)
    csv_path = "./data/line.csv"
    queries = {
      import: "INSERT INTO m_line VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
      prefs: "SELECT pref_cd, pref_name FROM m_pref",
      lines_by_pref: <<~SQL,
        SELECT l.line_cd, l.line_name
        FROM m_line l
        INNER JOIN m_station s ON s.line_cd = l.line_cd
        WHERE s.pref_cd = ?
          AND l.e_status = 0
          AND l.line_cd > 10000
        GROUP BY l.line_cd
      SQL
    }
    super(db, csv_path, queries)
  end

  def find_by_prefectures
    stmt1 = @stmts[:prefs]
    stmt2 = @stmts[:lines_by_pref]

    stmt1.execute.each do |row|
      stmt2.bind_param(1, row["pref_cd"])
      r = stmt2.execute.to_a

      yield row, r unless r.empty?

      stmt2.reset!
    end
  end
end

class StationRepository < Repository
  def initialize(db)
    csv_path = "./data/station.csv"
    queries = {
      import: "INSERT INTO m_station VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
      lines: "SELECT line_cd, line_name, lon, lat, zoom FROM m_line",
      stations_by_line: <<~SQL,
        SELECT station_cd, station_g_cd, station_name, lon, lat
        FROM m_station
        WHERE e_status = 0
          AND station_cd > 1000000
          AND line_cd = ?
        ORDER BY e_sort, station_cd
      SQL
      station_details: <<~SQL,
        SELECT
          s.pref_cd, s.line_cd, l.line_name, s.station_cd,
          s.station_g_cd, s.station_name, s.lon, s.lat
        FROM m_station s
        INNER JOIN m_line l ON l.line_cd = s.line_cd
        WHERE s.e_status = 0 AND s.station_cd > 1000000
        ORDER BY s.station_cd
      SQL
      station_lines: <<~SQL,
        SELECT
          l.line_cd,
          l.line_name,
          s.station_cd,
          s.station_g_cd,
          s.station_name,
          s.lon,
          s.lat
        FROM m_station s
        INNER JOIN m_line l ON l.line_cd = s.line_cd
        WHERE s.e_status = 0 AND s.station_cd > 1000000
        ORDER BY s.station_g_cd
      SQL
      station_groups: <<~SQL,
        SELECT s.pref_cd, s.line_cd, l.line_name, s.station_cd, s.station_name
        FROM m_station s
        INNER JOIN m_line l ON l.line_cd = s.line_cd
        WHERE s.e_status = 0
          AND s.station_cd > 1000000
          AND s.station_g_cd = ?
        ORDER BY s.e_sort, s.station_cd
      SQL
    }
    super(db, csv_path, queries)
  end

  def find_by_lines
    stmt1 = @stmts[:lines]
    stmt2 = @stmts[:stations_by_line]

    stmt1.execute.each do |row|
      stmt2.bind_param(1, row["line_cd"])
      r = stmt2.execute.to_a

      yield row, r unless r.empty?

      stmt2.reset!
    end
  end

  def station_details
    @stmts[:station_details].execute.each do |row|
      yield row["station_cd"], row.to_h
    end
  end

  def station_groups
    stmt1 = @stmts[:station_lines]
    stmt2 = @stmts[:station_groups]

    stmt1.execute.each do |row|
      stmt2.bind_param(1, row["station_g_cd"])
      yield row, stmt2.execute.to_a
      stmt2.reset!
    end
  end
end

class JoinRepository < Repository
  def initialize(db)
    csv_path = "./data/join.csv"
    queries = {
      import: "INSERT INTO m_station_join VALUES (?, ?, ?)",
      lines: "SELECT line_cd FROM m_line",
      joins: <<~SQL,
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
    }
    super(db, csv_path, queries)
  end

  def find_by_lines
    stmt1 = @stmts[:lines]
    stmt2 = @stmts[:joins]

    stmt1.execute.each do |row|
      stmt2.bind_param(1, row["line_cd"])
      r = stmt2.execute.to_a

      yield row["line_cd"], r unless r.empty?

      stmt2.reset!
    end
  end
end
