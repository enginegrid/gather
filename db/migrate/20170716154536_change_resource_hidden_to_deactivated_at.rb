class ChangeResourceHiddenToDeactivatedAt < ActiveRecord::Migration
  def change
    add_column :resources, :deactivated_at, :datetime
    execute("UPDATE resources SET deactivated_at = '2000-01-01 00:00:00' WHERE hidden = 't'")
    remove_column :resources, :hidden
  end
end
