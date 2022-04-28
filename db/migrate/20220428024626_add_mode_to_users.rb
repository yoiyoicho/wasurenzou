class AddModeToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :mode, :integer, null: false, default: 0
  end
end
