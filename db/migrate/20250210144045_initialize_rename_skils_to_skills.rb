class InitializeRenameSkilsToSkills < ActiveRecord::Migration[8.0]
  def change
    initialize_table_rename :skils, :skills
  end
end
