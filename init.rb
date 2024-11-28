# frozen_string_literal: true

require "csv"
require "fileutils"
require "json"
require "sqlite3"
require "./repository"
require "./xml"

FileUtils.mkdir_p(["./api/p", "./api/l", "./api/s", "./api/g", "./api/n"])

db = SQLite3::Database.new(":memory:")

records = lambda do |path, &block|
  CSV.foreach(path, encoding: "UTF-8").with_index(&block)
end

Migrator.create_tables(db)

repositories = {
  pref: PrefectureRepository.new(db),
  company: CompanyRepository.new(db),
  line: LineRepository.new(db),
  station: StationRepository.new(db),
  join: JoinRepository.new(db),
}

repositories.each_value do |r|
  r.import(records)
end

db.results_as_hash = true

repositories[:line].find_by_prefectures do |pref, data|
  pref_cd = pref["pref_cd"]
  builder = XMLBuilder.lines_by_prefectures(pref, data)

  File.open("./api/p/#{pref_cd}.xml", "w") do |f|
    f << builder.to_xml
  end

  File.open("./api/p/#{pref_cd}.json", "w") do |f|
    f.write(JSON.pretty_generate({ line: data }))
  end
end

repositories[:station].find_by_lines do |line, data|
  line_cd = line["line_cd"]
  builder = XMLBuilder.stations_by_lines(line, data)

  File.open("./api/l/#{line_cd}.xml", "w") do |f|
    f << builder.to_xml
  end

  File.open("./api/l/#{line_cd}.json", "w") do |f|
    f.write(JSON.pretty_generate({ station_l: data }))
  end
end

repositories[:station].station_details do |station_cd, data|
  builder = XMLBuilder.station_details(data)

  File.open("./api/s/#{station_cd}.xml", "w") do |f|
    f << builder.to_xml
  end

  File.open("./api/s/#{station_cd}.json", "w") do |f|
    f.write(JSON.pretty_generate({ station: data }))
  end
end

repositories[:station].station_groups do |station, data|
  station_g_cd = station["station_g_cd"]
  builder = XMLBuilder.station_groups(station, data)

  File.open("./api/g/#{station_g_cd}.xml", "w") do |f|
    f << builder.to_xml
  end

  File.open("./api/g/#{station_g_cd}.json", "w") do |f|
    f.write(JSON.pretty_generate({ station_g: data }))
  end
end

repositories[:join].find_by_lines do |line_cd, data|
  builder = XMLBuilder.joins_by_lines(data)

  File.open("./api/n/#{line_cd}.xml", "w") do |f|
    f << builder.to_xml
  end

  File.open("./api/n/#{line_cd}.json", "w") do |f|
    f.write(JSON.pretty_generate({ station_join: data }))
  end
end

repositories.each_value(&:close)
