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

    if self.updated_time + Rails.application.config.update_interval > now
      logger.debug("need to wait #{Rails.application.config.update_interval} seconds")
      return
    end

    #now get updated values
    self.updated_time = now

    job_data = JenkinsJobData.new(jenkins_url,now)

    self.test_count = job_data.stats[:first_build_test_count]
    self.prev_test_count = job_data.stats[:last_build_test_count]
    self.num_builds = job_data.stats[:number_of_builds]
    self.num_failed_builds = job_data.stats[:number_of_failed_builds]

    self.save
  end
end
