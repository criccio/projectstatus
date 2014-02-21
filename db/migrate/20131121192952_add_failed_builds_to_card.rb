class AddFailedBuildsToCard < ActiveRecord::Migration
  def change
    add_column :cards, :num_failed_builds, :integer, default: 0
  end
end
