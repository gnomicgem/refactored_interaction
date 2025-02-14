class AddForeignKeyFromUserSkillsToSkill < ActiveRecord::Migration[8.0]
  def change
    add_foreign_key :user_skills, :skills, validate: false
  end
end
