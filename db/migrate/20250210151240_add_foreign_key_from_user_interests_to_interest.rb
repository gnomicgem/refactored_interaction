class AddForeignKeyFromUserInterestsToInterest < ActiveRecord::Migration[8.0]
  def change
    add_foreign_key :user_interests, :interests, validate: false
  end
end
