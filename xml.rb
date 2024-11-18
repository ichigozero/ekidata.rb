require 'nokogiri'

module XMLBuilder
  def self.lines_by_prefectures(pref, data)
    Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.ekidata(version: 'ekidata.jp pref api 1.0') do
        xml.pref do
          xml.code pref['pref_cd']
          xml.name pref['pref_name']
        end
        data.each do |d|
          xml.line do
            xml.line_cd d['line_cd']
            xml.line_name d['line_name']
          end
        end
      end
    end
  end

  def self.stations_by_lines(line, data)
    Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.ekidata(version: 'ekidata.jp pref api 1.0') do
        xml.line do
          xml.line_cd line['line_cd']
          xml.line_name line['line_name']
          xml.line_lon line ['lon']
          xml.line_lat line['lat']
          xml.line_zoom line['zoom']
        end
        data.each do |d|
          xml.station do
            xml.station_cd d['station_cd']
            xml.station_g_cd d['station_g_cd']
            xml.station_name d['station_name']
            xml.lon d['lon']
            xml.lat d['lat']
          end
        end
      end
    end
  end

  def self.station_details(data)
    Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.ekidata(version: 'ekidata.jp pref api 1.0') do
        xml.station do
          xml.pref_cd data[:pref_cd]
          xml.line_cd data[:line_cd]
          xml.line_name data[:line_name]
          xml.station_cd data[:station_cd]
          xml.station_g_cd_ data[:station_g_cd]
          xml.station_name data[:station_name]
          xml.lon data[:lon]
          xml.lat data[:lat]
        end
      end
    end
  end

  def self.joins_by_lines(data)
    Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.ekidata(version: 'ekidata.jp pref api 1.0') do
        data.each do |d|
          xml.station do
            xml.station_cd1 d['station_cd1']
            xml.station_cd2 d['station_cd2']
            xml.station_name1 d['station_name1']
            xml.station_name2 d['station_name2']
            xml.lat1 d['lat1']
            xml.lon1 d['lon1']
            xml.lat2 d['lat2']
            xml.lon2 d['lon2']
          end
        end
      end
    end
  end
end
