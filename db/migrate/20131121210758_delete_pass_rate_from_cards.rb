class DeletePassRateFromCards < ActiveRecord::Migration
  def change
    remove_column :cards, :pass_rate
  end
end
