class AddTimeTrackerEnabled < ActiveRecord::Migration
  def up 
    add_column :user_preferences, :time_tracker_enabled, :boolean, :default => true
  end
  def down
    remove_columne :user_preferences, :time_tracker_enabled
  end
end