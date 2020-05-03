#!/usr/bin/ruby
# @Author: Sky
# @Date:   2019-03-26 18:48:29
# @Last Modified by:   Sky
# @Last Modified time: 2019-06-13 13:12:56

require "json"
require 'net/http'
require 'net/https'
require 'open-uri'
require 'uri'
require 'thread'
require 'colorize'
require 'logger'
require 'openssl'
require 'nokogiri'

$log = Logger.new(STDOUT)

class FFMPEG
  def initialize
    @name = "FFMPEG"
    @config = JSON.parse(File.read("config.json"))["FFMPEG"]
  end

  def fetch(path)
    $log.debug "PAGE_DOWNLOAD page #{path}"
    uri = URI.parse(@config["host"])
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(path)
    request["referer"] = uri.to_s
    response = http.request(request)
    response.body
  end

  def update_page
    return Nokogiri::HTML.parse(fetch(@config["path"]))
  end

  def get_package_url
    page = update_page.css("tbody a").select{
        |a|
        a.text.include? "2019"
    }
    [@config["host"], @config["path"], page.last["href"]].join("")
  end

  def download(url, save)
      system("wget -c \"#{url}\" -O \"#{save}\"")
  end

  def extract(path, filename)
      command = [
        "7z", "x", "\"#{path}\"", "-o\".\"", "-aoa"
      ].join(" ")
      p command
      system(command)
      system("robocopy \"#{filename.gsub(".zip", "")}\" \"#{@config["output"]}\" /MOVE /E")
  end

  def update
    url = get_package_url
    filename = url.split("/").last
    save = "packages/#{filename}"
    return "#{@name} is upto-date" if File.exist?(save)
    download(url, save)
    extract(save, filename)
  end
end
