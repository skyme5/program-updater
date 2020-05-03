#!/usr/bin/ruby
# @Author: Sky
# @Date:   2019-03-26 18:49:06
# @Last Modified by:   Sky
# @Last Modified time: 2019-07-24 12:40:38

require_relative("ffmpeg")
# require_relative("nginx")
# require_relative("UMATRIX")
require_relative("RIPME")
# require_relative("SingleFile")
# require_relative("ReviewHeatmap")

for package_downloader in [FFMPEG]#, NGINX, UMATRIX, RIPME, ReviewHeatmap]
    $log.debug("#{package_downloader} downloader initialize")
    downloader = package_downloader.new
    downloader.update
end
