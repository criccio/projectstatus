class Project < ActiveRecord::Base
  extend FriendlyId
  has_many :cards, dependent: :destroy
  validates :title, presence: true,
            length: { minimum: 5 }

  friendly_id :title, use: :slugged

  attr_accessor :test_message, :build_message

  def generate_messages
    total_builds = 0
    total_failed_builds = 0
    total_tests = 0
    total_prev_tests = 0
    self.cards.each do | card |
      total_builds += card.num_builds
      total_failed_builds += card.num_failed_builds
      total_tests += card.test_count
      total_prev_tests += card.prev_test_count
    end
    passrate = ((total_builds - total_failed_builds) / total_builds.to_f) * 100
    if total_tests == total_prev_tests
      direction = 'no'
      difference = 'change'
    else
      if total_tests > total_prev_tests
        direction = 'up'
        difference = total_tests - total_prev_tests
      else
        direction = 'down'
        difference = total_prev_tests - total_tests
      end
    end
    self.test_message = "#{title} builds green #{passrate.round(2)}% of the time, #{total_failed_builds} failed out of #{total_builds} total #{'build'.pluralize(total_builds)}"
    self.build_message = "#{title} Tests executed with each checkin #{direction} #{difference} to #{total_tests}"
  end

end
