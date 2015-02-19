class JenkinsJobData
  attr_accessor :url
  attr_accessor :auth_details
  attr_accessor :participant_constraint_list
  attr_accessor :stats
  attr_accessor :update_start_time

  def initialize(jenkins_url, update_time)
    @url = "#{jenkins_url}/api/json?tree=builds[number,timestamp,id,result,actions[totalCount],changeSet[items[author[fullName]]]]"

    #Load config that might be related to this jenkins job
    @auth_details = NIL
    @participant_constraint_list = NIL
    Rails.application.config.jenkins_auth_map.each do | key,value |
      if jenkins_url =~ /#{key}/
        @auth_details = value
      end
    end
    Rails.application.config.jenkins_participant_map.each do | key,value |
      if jenkins_url =~ /#{key}/
        @participant_constraint_list = value
      end
    end

    @stats = {:number_of_builds => 0, :number_of_failed_builds => 0, :first_build_test_count => 0, :last_build_test_count => 0}
    @update_start_time = update_time
    load_data
  end

  private
  def load_data
    if auth_details.nil?
      response = HTTParty.get(@url)
    else
      response = HTTParty.get(@url, :basic_auth =>{:username => auth_details[:user], :password => auth_details[:pw]})
    end
    builds = response['builds']
    builds = [] if response['builds'].nil?
    builds.each do | build |
      buildTime = Time.at(build['timestamp'].to_f / 1000)
      if buildTime > @update_start_time - Rails.application.config.build_window
        this_build_counts = true
        unless @participant_constraint_list.nil?
          #only count the build if one of our team members was a participant
          build_participants = []
          build['changeSet']['items'].each { |item| build_participants << item['author']['fullName'] }
          this_build_counts = false
          unless build_participants.size == 0
            if @participant_constraint_list[:users].any? {|user| build_participants.include? user}
              this_build_counts = true
              Rails.logger.debug("we participated in this build #{@url} #{build['number']}")
            end
          end
        end
        if this_build_counts
          @stats[:number_of_builds] += 1
          unless build['result'] =~ /SUCCESS/
            @stats[:number_of_failed_builds] += 1
          end
          build_actions = build['actions']
          build_actions = [] if build['actions'].nil?
          build_actions.each do | actions |
            unless actions['totalCount'].nil?
              @stats[:first_build_test_count] = actions['totalCount'].to_i unless @stats[:first_build_test_count] > 0
              @stats[:last_build_test_count] = actions['totalCount'].to_i
            end
          end
        end
      end
    end

  end

end