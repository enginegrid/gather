class AddHouseholdNameIndex < ActiveRecord::Migration[4.2]
  def change
    add_index :households, :name
  end
end
