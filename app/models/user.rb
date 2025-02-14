class User < ApplicationRecord
  has_many :user_interests, dependent: :destroy
  has_many :interests, through: :user_interests

  has_many :user_skills, dependent: :destroy
  has_many :skills, through: :user_skills

  accepts_nested_attributes_for :skills
  accepts_nested_attributes_for :interests
end
