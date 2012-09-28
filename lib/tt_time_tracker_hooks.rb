# This class hooks into Redmine's View Listeners in order to add content to the page
class TimeTrackerHooks < Redmine::Hook::ViewListener
  render_on :view_issues_context_menu_start, :partial => 'time_trackers/update_context'

  def view_layouts_base_html_head(context = {})
    css = stylesheet_link_tag 'time_tracker', :plugin => 'redmine_time_tracker'
    css += stylesheet_link_tag 'autocomplete', :plugin => 'redmine_time_tracker'
    js = javascript_include_tag 'time_tracker.js', :plugin => 'redmine_time_tracker'
    js += javascript_include_tag 'autocomplete.js', :plugin => 'redmine_time_tracker'
    css + js
  end
  
  render_on :view_my_account, :partial => 'account_settings/time_tracker_account_settings', :layout => false
  
  render_on :view_projects_show_sidebar_bottom, :partial => 'projects/time_tracker_projects_show_sidebar_bottom', :layout => false
  render_on :view_issues_sidebar_queries_bottom, :partial => 'projects/time_tracker_projects_show_sidebar_bottom', :layout => false
  
  
end
