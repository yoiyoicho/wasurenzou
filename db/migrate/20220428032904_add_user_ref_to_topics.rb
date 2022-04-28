class AddUserRefToTopics < ActiveRecord::Migration[6.1]
  def change
    add_reference :topics, :user, null: false, foreign_key: true
  end
end
