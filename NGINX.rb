#!/usr/bin/ruby
# @Author: Sky
# @Date:   2019-03-26 18:48:29
# @Last Modified by:   Sky
# @Last Modified time: 2019-06-20 17:30:01

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

class NGINX
  def initialize
    @name = "NGINX"
    @config = JSON.parse(File.read("config.json"))["NGINX"]
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
    packages = update_page.css("a").map{
        |a|
        a.text
    }.select{
      |a|
      a.include?("nginx-") && a.include?(".zip")
    }.sort_by {
      |v| Gem::Version.new(v.split("-").last.split(".zip").first)
    }
    [@config["host"], @config["path"], packages.last].join("")
  end

  def download(url, save)
      system("wget -c \"#{url}\" -O \"#{save}\"")
  end

  def extract(path, filename)
      command = [
        "7z", "x", "\"#{path}\"", "-o\".\"", "-aoa", "#{@config["extract_exclude"]}"
      ].join(" ")


      $log.info "extracting #{path}"
      p command
      system(command)

      $log.info "executing command before installation #{@config["command_before"]}"
      system(@config["command_before"])

      $log.info "waiting for the process to shutdown"
      sleep 3

      $log.info "installating files to #{@config["output"]}"
      system("robocopy \"#{filename.gsub(".zip", "")}\" \"#{@config["output"]}\" /MOVE /E")

      $log.info "executing command after installation #{@config["command_after"]}"
      system(@config["command_after"])
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
