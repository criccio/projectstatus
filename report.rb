#!/usr/bin/ruby
#should be run from directory the script resides in

require 'xmlsimple'
require 'httparty'
require 'json'


# purpose of this script
# intended to run once a week to provide the overall week stats
# it processes the existing results.txt file
# it will report the number of builds for the week, the number we participated in, and the number of those that failed/passed
# this script doesn't clean up the results.txt file

participant_map = {
    users: [
        'criccio'
    #TODO add additional user aliases here
]}


builds_we_participated_in = 0
builds_failed = 0
builds_passed = 0
total_tests_added = 0

build_data = {}
File.open('results.txt', 'r') { |f|
  f.each_line do |line|
    entries = line.chomp.split(',')
    build_url = entries[1]
    build_number = build_url.split('/').last.to_i
    build_data[build_number] = entries
  end
}

processed_builds = {}
build_data.each do |build_number,entries|
  build_url = entries[1]
  build_number_int = build_number.to_i
  unless processed_builds.include?(build_number_int)
    #don't process duplicate entries in the file
    build_date_time = DateTime.parse(entries[0])
    if build_date_time > DateTime.now - 7
      #timeframe means we should include this build in our report
      entries[3] = '' if entries[3].nil?
      build_participants = entries[3].split(':')
      unless build_participants.size == 0
        if participant_map[:users].any? {|user| build_participants.include? user}
          #really include this one, since we participated in it
          build_result = entries[2]
          test_count = entries[4].to_i
          if build_data.include? (build_number_int-1)
            previous_test_count = build_data[build_number_int-1][4].to_i
          else
            previous_test_count = test_count #if we don't have data on the previous build, assume no new tests
          end
          test_count = previous_test_count if test_count == 0  #if no tests ran in this build, assume no new tests
          tests_added = test_count - previous_test_count
          tests_added = 0 if tests_added < -50  # if the amount of tests changed by more than removing 50 tests, likely the build was aborted, so assume no new tests
          puts("we participated in this build #{build_url} #{build_number} #{build_participants} added #{tests_added} tests")
          builds_we_participated_in += 1
          total_tests_added += tests_added
          (build_result =~ /failed/) ? builds_failed += 1 : builds_passed += 1
          processed_builds[build_number_int] = 'x'
        end
      end
    end
  end
#  end
#}

end

pass_rate = ((builds_we_participated_in - builds_failed) / builds_we_participated_in.to_f) * 100
puts "Total builds we participated in: #{builds_we_participated_in}, Number passed: #{builds_passed}, Number failed: #{builds_failed}, Total Passrate: #{pass_rate.round(2)}%, Added #{total_tests_added} tests"
