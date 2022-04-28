class User < ApplicationRecord
  has_many :topics, dependent: :destroy
  validates :line_user_id, presence: true
end
