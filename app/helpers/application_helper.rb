module ApplicationHelper
  def time_tracker_for(user)
    TimeTracker.where(:user_id => user.id).first
  end

  def status_from_id(status_id)
    IssueStatus.where(:id => status_id).first
  end

  def statuses_list()
    IssueStatus.all
  end

  def to_status_options(statuses)
    options_from_collection_for_select(statuses, 'id', 'name')
  end

  def new_transition_from_options(transitions)
    statuses = []
    statuses_list().each { |status|
      statuses << status unless transitions.has_key?(status.id.to_s)
    }
    to_status_options(statuses)
  end

  def new_transition_to_options()
    to_status_options(statuses_list())
  end

  def global_allowed_to?(user, action)
    return false if user.nil?

    projects = Project.all
    projects.each { |p|
      if user.allowed_to?(action, p)
        return true
      end
    }

    false
  end
  
  def time_tracker_button_tag(object, user, options={})
    content_tag("span", time_tracker_link(object, user), :class => time_tracker_css(User.current()))
  end
  
  def time_tracker_link(object, user)
     time_tracker = time_tracker_for(user) 
     if !time_tracker.nil? 
        # A time tracker exists, display the stop action 
        link_to l(:stop_time_tracker).capitalize + ' #' + time_tracker.issue_id.to_s,
          {:controller => '/time_trackers', :action => 'stop', :time_tracker => {:issue_id => object.id}},
          :class => 'icon icon-stop'
     elsif !object.nil? and !object.project.nil? and user.allowed_to?(:log_time, object.project) 
        # No time tracker is running, but the user has the rights to track time on this issue 
        # Display the start time tracker action 
        link_to l(:start_time_tracker).capitalize + ' #' + object.id.to_s,
          {:controller => '/time_trackers', :action => 'start', :time_tracker => {:issue_id => object.id}},
          :class => 'icon icon-start'
     end 
  end
  
  def time_tracker_css(object)
    "#{object.class.to_s.underscore}-#{object.id}-time_tracker"
  end

end
