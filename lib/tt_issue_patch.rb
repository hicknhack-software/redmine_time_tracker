module IssuePatch
    
  def self.included(base)
    unloadable
    
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      before_save :before_save_time_tracker
    end
  end
  
  module ClassMethods
  end
  
  module InstanceMethods
    def close_time_tracker_issue
      logger.debug "Issue changes: #{self.changes}"
      if self.closed?() and status_id_changed? and  Setting.plugin_redmine_time_tracker[:stop_on_close]
        logger.debug "Time tracker post save hook called: issue #{self.id}: #{self.subject}"
        time_trackers = TimeTracker.where("issue_id = ?", self.id)
        time_trackers.each do |time_tracker|
          logger.debug "Stopping time tracker for #{time_tracker.user.name()}, issue = #{time_tracker.issue_id}"
          time_tracker.stop
        end
      end
  end # InstanceMethods
    
    def before_save_time_tracker
      close_time_tracker_issue
    end
  end #InstanceMethods
  
end #IssuePatch

Issue.send(:include, IssuePatch)