class ValidateForeignKeyOnUserInterests < ActiveRecord::Migration[8.0]
  def change
    validate_foreign_key :user_interests, :interests
  end
end
