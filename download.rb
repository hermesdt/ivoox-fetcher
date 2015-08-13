require 'nokogiri'
require 'net/http'

class Fetcher < Struct.new(:base_url)
  BASE_URL = 'http://www.ivoox.com/podcast-radio-fitness-revolucionario_sq_f1115589_1.html?o=all'

  def self.fetch!
    self.new(BASE_URL).fetch
  end

  def log msg
    puts msg
  end

  def fetch
    log('... Starting fetch ...')
    rss_url = get_rss_url base_url
    sample_mp3_url = get_sample_rss_mp3_url rss_url

    base_page = Net::HTTP.get_response(URI.parse(base_url)).body
    pages = Nokogiri::HTML(base_page).css(".paginacion a").select{|a| a.text.to_i > 0}.map{|a| a['href']}
    pages = [base_url] | pages

    pages.each do |page|
      download_page(page, sample_mp3_url)
    end
  end

  def get_rss_url base_url
    html = Net::HTTP.get_response(URI.parse(base_url)).body
    Nokogiri::HTML(html).css("link[rel='alternate'][type='application/rss+xml']")[0]['href']
  end

  def get_sample_rss_mp3_url rss_url
    xml = Net::HTTP.get_response(URI.parse(rss_url)).body
    Nokogiri::XML(xml).css("item enclosure")[0]['url']
  end

  def download_page page, sample_mp3_url
    log("[#] Download page: #{page}")
    html = Net::HTTP.get_response(URI.parse(base_url)).body
    urls = Nokogiri::HTML(html).css(".content a.titulo").map{|a| a['href']}
    urls.each do |url|
      audio_id = url.match(/-mp3_rf_(\d+)_1/)[1]
      log("[*] Downloading audio_id: #{audio_id}")
      download_audio(audio_id, sample_mp3_url)
    end
  end

  def download_audio audio_id, sample_mp3_url
    sample_mp3_url = 'http://www.ivoox.com/episodio-38-piel-colgante-estrias-retencion-liquidos-dieta_mf_6614024_feed_1.mp3'
    mp3_url = sample_mp3_url.gsub(/mf_\d+_feed/, "mf_#{audio_id}_feed")

    puts mp3_url
    system "wget -nv -c #{mp3_url} -O #{audio_id}.mp3"
  end

end

Fetcher.fetch!