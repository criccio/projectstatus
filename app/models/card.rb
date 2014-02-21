class Card < ActiveRecord::Base
  belongs_to :project
  validates :title, presence: true,
            length: { minimum: 5 }
  validates :jenkins_url, presence: true
  validate :jenkins_url_is_valid

  def jenkins_url_is_valid
    unless %w( http https ).include?(URI.parse(jenkins_url).scheme)
      errors.add(:jenkins_url, 'is not a uri')
    end
  rescue URI::BadURIError
    errors.add(:jenkins_url, 'is a bad uri')
  rescue URI::InvalidURIError
    errors.add(:jenkins_url, 'is an invalid uri')
  end

  def build_report
    totalBuilds = self.num_builds
    failedBuilds = self.num_failed_builds
    passrate = ((totalBuilds - failedBuilds) / totalBuilds.to_f) * 100
    "#{passrate.round(2)}% #{failedBuilds} failed out of #{totalBuilds} total #{'build'.pluralize(totalBuilds)}"
  end

  def test_count_report
    if self.test_count == self.prev_test_count
      direction = 'no'
      difference = 'change'
    else
      if self.test_count > self.prev_test_count
        direction = 'up'
        difference = self.test_count - self.prev_test_count
      else
        direction = 'down'
        difference = self.prev_test_count - self.test_count
      end
    end
    "#{self.test_count} #{'test'.pluralize(self.test_count)} #{direction} #{difference} since last week"
  end

  def update_info
    now = Time.now

    if self.updated_time + 20.minutes > now #TODO configure update interval
      logger.debug('need to wait 20 minutes')
      return
    end

    #now get updated values
    self.updated_time = now

    path = "#{jenkins_url}/api/json?tree=builds[number,status,timestamp,id,result,actions[totalCount]]"

    auth_details = NIL
    Rails.application.config.jenkins_auth_map.each do | key,value |
      if jenkins_url =~ /#{key}/
        auth_details = value
      end
    end

    if auth_details.nil?
      response = HTTParty.get(path)
    else
      response = HTTParty.get(path, :basic_auth =>{:username => auth_details[:user], :password => auth_details[:pw]})
    end

    number_of_builds = 0
    number_of_failed_builds = 0
    first_build_test_count = 0
    last_build_test_count = 0
    builds = response['builds']
    builds = [] if response['builds'].nil?
    builds.each do | build |
      buildTime = Time.at(build['timestamp'].to_f / 1000)
      if buildTime > now - 7.days  # TODO configurable time window for builds
        number_of_builds += 1
        unless build['result'] =~ /SUCCESS/
          number_of_failed_builds += 1
        end
        build['actions'].each do | actions |
          unless actions['totalCount'].nil?
            first_build_test_count = actions['totalCount'].to_i unless first_build_test_count > 0
            last_build_test_count = actions['totalCount'].to_i
          end
        end
      end
    end

    self.test_count = first_build_test_count
    self.prev_test_count = last_build_test_count
    self.num_builds = number_of_builds
    self.num_failed_builds = number_of_failed_builds

    self.save
  end
end
