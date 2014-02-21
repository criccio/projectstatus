class DeletePrevUpdateTimeFromCards < ActiveRecord::Migration
  def change
    remove_column :cards, :prev_updated_time
  end
end
