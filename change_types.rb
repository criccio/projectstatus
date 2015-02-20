#!/usr/bin/ruby
#should be run from directory the script resides in

# purpose of this script
# collect all the files changed in changelists that were built - to find builds that were kicked off for changes not typically needing a build (like txt files)

# another script can be used to grab the vitals, and provide a week view

require 'xmlsimple'
require 'httparty'
require 'json'
require 'nokogiri'

def getJobInfo(url)
  config = XmlSimple.xml_in(HTTParty.get(url))
  return config['entry']
end


jobinfo = getJobInfo('your job url goes here/rssAll')
jobinfo.each { |entry|
  File.open('changes_by_job.txt', 'a') { |f|
    unless entry['title'][0] =~ /.*aborted.*/
      build_date_time = entry['published'][0]
      build_url = entry['link'][0]['href']
      build_result = (entry['title'][0] =~ /.*broken.*/) ? 'failed' : 'passed'


      response = HTTParty.get("#{build_url}/api/json")
      file_types_changed = []
      if response.code == 200
        response['changeSet']['items'].each { |item|
          item['affectedPaths'].each { | file_changed |
            file_types_changed << File.extname(file_changed)
          }
        }
      end
      duration = response['duration']




      result = "#{build_date_time},#{build_url},#{build_result},#{duration},#{file_types_changed.uniq.join(':')}"
      f.puts(result)
      f.flush
    end
  }
}