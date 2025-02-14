class CreateUserSkills < ActiveRecord::Migration[8.0]
  def change
    create_table :user_skills do |t|
      t.belongs_to :user, foreign_key: true
      t.belongs_to :skill, foreign_key: false
      t.timestamps
    end
  end
end
