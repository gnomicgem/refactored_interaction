class ValidateForeignKeyOnUserSkills < ActiveRecord::Migration[8.0]
  def change
    validate_foreign_key :user_skills, :skills
  end
end
