#!/usr/bin/ruby
# @Author: Sky
# @Date:   2019-03-26 18:48:29
# @Last Modified by:   Sky
# @Last Modified time: 2019-07-17 09:30:03

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

class RIPME
  def initialize
    @name = "RIPME"
    @config = JSON.parse(File.read("config.json"))["RIPME"]
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
    package = update_page.at(".repository-content .release-entry .release details .Box a")

    {"version" => package["href"].split("/")[-2], "url" => @config["host"] + package["href"]}
  end

  def download(url, save)
    system("wget -c \"#{url}\" -O \"#{save}\"")
  end

  def extract(path, output)
    command = [
      "copy", "\"#{path.gsub("/", "\\")}\"", "\"#{output.gsub("/", "\\")}\"", "/Y"
    ].join(" ")

    $log.info "copying to #{output}"
    puts command
    system(command)
  end

  def update
    package = get_package_url
    version = package["version"]
    filename = package["url"].split("/").last
    save = "packages/#{version}-#{filename}"
    # return "#{@name} is upto-date" if File.exist?(save)
    download(package["url"], save)
    extract(save, @config["output"])
  end
end