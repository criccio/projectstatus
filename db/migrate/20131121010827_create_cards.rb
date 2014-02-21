class CreateCards < ActiveRecord::Migration
  def change
    create_table :cards do |t|
      t.string :title
      t.string :jenkins_url
      t.integer :test_count, default: 0
      t.datetime :updated_time, default: DateTime.current
      t.integer :prev_test_count, default: 0
      t.datetime :prev_updated_time, default: DateTime.current
      t.integer :num_builds, default: 0
      t.decimal :pass_rate, default: 0.0
      t.references :project, index: true

      t.timestamps
    end
  end
end
