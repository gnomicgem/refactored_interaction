class FinalizeRenameSkilsToSkills < ActiveRecord::Migration[8.0]
  def change
    finalize_table_rename :skils, :skills
  end
end
