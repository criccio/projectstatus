#!/usr/bin/ruby
#should be run from directory the script resides in

# purpose of this script
# once a day it will wake up, scan the rssAll feed for the main build, and grab vitals for all the builds listed in the rssAll
# if the job details page 404's (because it expired) that build will not be saved to the output
# results go to console, which can be redirected to output file

# another script can be used to grab the vitals, and provide a week view

require 'xmlsimple'
require 'httparty'
require 'json'
require 'nokogiri'

HTTParty::Basement.default_options.update(verify: false)

def getJobInfo(url)
  config = XmlSimple.xml_in(HTTParty.get(url))
  return config['entry']
end

def get_build_participants(build_url)
  response = HTTParty.get("#{build_url}/api/json")
  build_participants = []
  if response.code == 200
    response['changeSet']['items'].each { |item| build_participants << item['author']['fullName'] }
  end
  build_participants
end

def get_test_count(build_url)
  #assumes you archive a unit test report in the Unit_Test_Report directory
  response = HTTParty.get("#{build_url}/Unit_Test_Report/index.html")
  unit_test_count = 0
  if response.code == 200
    unit_test_count = response.body.scan(/(\d+)<\/div>/)[0][0]
  end
  #assumes you archive a integration test report in the Integration_Test_Report directory
  response = HTTParty.get("#{build_url}/Integration_Test_Report/index.html")
  int_test_count = 0
  if response.code == 200
    int_test_count = response.body.scan(/(\d+)<\/div>/)[0][0]
  end
  unit_test_count.to_i + int_test_count.to_i
end

jobinfo = getJobInfo('put your job url here/rssAll')
jobinfo.each { |entry|
  File.open('results.txt', 'a') { |f|
    unless entry['title'][0] =~ /.*aborted.*/
      build_date_time = entry['published'][0]
      build_url = entry['link'][0]['href']
      build_result = (entry['title'][0] =~ /.*broken.*/) ? 'failed' : 'passed'
      build_participants = get_build_participants(build_url)
      test_count=0
      #test_count = get_test_count(build_url)
      result = "#{build_date_time},#{build_url},#{build_result},#{build_participants.join(':')},#{test_count}"
      f.puts(result)
      f.flush
    end
  }
}
