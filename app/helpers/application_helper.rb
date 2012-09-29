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
  
  def time_tracker_button_tag(user, options={})
    content_tag("span", time_tracker_link(user, options), :class => time_tracker_css(User.current()))
  end
  
  def time_tracker_link(user, options)
     time_tracker = time_tracker_for(user) 
     if !time_tracker.nil?
       stop_label = '' 
       # A time tracker exists, display the stop action
       if !time_tracker.issue_id.nil?
         stop_label += ' #' + time_tracker.issue_id.to_s
       elsif !time_tracker.project_id.nil?
         stop_label += ' ' + Project.find(time_tracker.project_id).name unless Project.find(time_tracker.project_id).nil?
       else stop_label += ' ' + time_tracker.comments.to_s
       end 
       
       link_to l(:stop_time_tracker).capitalize + stop_label,
                   {:controller => '/time_trackers', :action => 'stop', :time_tracker => {}},
                   :class => 'icon icon-stop'
     elsif !options[:project].nil? and user.allowed_to?(:use_time_tracker_plugin, nil, :global => true) and user.allowed_to?(:log_time, options[:project])
        # No time tracker is running, but the user has the rights to track time on this issue 
        # Display the start time tracker action
       if options[:issue].nil?
         link_to l(:start_time_tracker).capitalize + ' ' +  options[:project].name,
             {:controller => '/time_trackers', :action => 'start', :time_tracker => {:project_id => options[:project].id}},
           :class => 'icon icon-start'
       else
         link_to l(:start_time_tracker).capitalize + ' #' +  options[:issue].id.to_s,
             {:controller => '/time_trackers', :action => 'start', :time_tracker => {:issue_id => options[:issue].id,
             :project_id => options[:project].id}},
           :class => 'icon icon-start'
       end 

     end 
  end
  
  def time_tracker_css(object)
    "#{object.class.to_s.underscore}-#{object.id}-time_tracker"
  end

end
