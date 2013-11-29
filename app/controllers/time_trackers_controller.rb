class TimeTrackersController < ApplicationController
  unloadable

  menu_item :time_tracker_menu_tab_overview
  before_filter :js_auth, :authorize_global
  before_filter :load_issue_status
  after_filter :save_issue_status
  around_filter :error_handling, :only => [:stop, :start]
  accept_api_auth :update

  helper :time_trackers

  # we could start an empty timeTracker to track time without any association.
  # we also can give some more information, so the timeTracker could be automatically associated later.
  def start(args = {})
    default_args= {:issue_id => nil, :comments => nil, :activity_id => nil, :project_id => nil}
    args = default_args.merge(args)

    @time_tracker = get_current
    if @time_tracker.new_record?
      # TODO work out a nicer way to get the params from the form
      unless params[:time_tracker].nil?
        args[:issue_id] = params[:time_tracker][:issue_id] if args[:issue_id].nil?
        args[:comments] = params[:time_tracker][:comments].strip if args[:comments].nil? and not params[:time_tracker][:comments].nil?
        args[:activity_id] = params[:time_tracker][:activity_id].strip if args[:activity_id].nil? and not params[:time_tracker][:activity_id].nil?
        args[:project_id] = params[:time_tracker][:project_id].strip if args[:project_id].nil? and not params[:time_tracker][:project_id].nil? and args[:issue_id].blank?
      end
      # Autochange Issue status to in Progress
      unless args[:issue_id].nil?
        @issue = Issue.find args[:issue_id]
        @old_status = @issue.status_id
        @new_status = Setting.plugin_redmine_time_tracker[:issue_progress_state]
        if @new_status.nil?
          flash[:notice] = l(:notice_no_prog_state)
        else
          @issue.status_id = @new_status
          @issue.save
        end
      end
      # parse comments for issue-id
      if args[:issue_id].nil? && !args[:comments].nil? && args[:comments].match(/\A\#(\d+)/)
        issue_id = args[:comments].match(/\A\#(\d+)/)[1].to_i
        issue = help.issue_from_id(issue_id)
        unless issue.nil?
          args[:issue_id] = issue_id
          args[:comments].sub!(/\A\##{issue_id}(\s+#{issue.subject})?\s*/, '')
        end
      end


      @time_tracker = TimeTracker.new(:issue_id => args[:issue_id], :comments => args[:comments], :activity_id => args[:activity_id], :project_id => args[:project_id])
      if @time_tracker.start
        flash[:notice] = l(:start_time_tracker_success)
      else
        flash[:error] = l(:start_time_tracker_error)
      end
    else
      flash[:error] = l(:time_tracker_already_running_error)
    end
    unless request.xhr?
      redirect_to :back
    else
      render :partial => 'flash_messages'
    end
  end

  def stop
    @time_tracker = get_current
    if @time_tracker.nil?
      flash[:error] = l(:no_time_tracker_running)
      unless request.xhr?
        redirect_to :back
      else
        render :partial => 'flash_messages'
      end
    else
      unless params[:time_tracker].nil?
        @time_tracker.issue_text = params[:time_tracker][:issue_text]
        @time_tracker.comments = params[:time_tracker][:comments]
        @time_tracker.activity_id = params[:time_tracker][:activity_id]
      end
      unless @time_tracker.issue_id.nil?
        @issue = Issue.find(@time_tracker.issue_id)
        if params[:manage_ticket] != '1'
          @issue.status_id = @old_status
          @issue.save
        end
      end
      @time_tracker.stop
      flash[:error] = l(:stop_time_tracker_error) unless @time_tracker.destroyed?
      @time_tracker = get_current
      
      flash[:notice] = l(:stop_time_tracker_success)
      if !params[:start_new_time_tracker].nil?
        start({:issue_id => params[:start_new_time_tracker]})
      else
        unless request.xhr?
          if params[:manage_ticket] == '1'
            redirect_to edit_issue_path(@issue)
          else
            redirect_to :back
          end
        else
          render :partial => 'flash_messages'
        end
      end
    end
  end

  def delete
    time_tracker = TimeTracker.where(:id => params[:id]).first
    if User.current.id == time_tracker.user_id && User.current.allowed_to?([:tt_edit_own_time_logs], {}) || User.current.allowed_to_globally?([:tt_edit_time_logs], {}) # user could only delete his own entries, except he's admin
      time_tracker.destroy
    else
      flash[:error] = l(:time_tracker_delete_fail)
    end
    flash[:notice] = l(:time_tracker_delete_success)
    if !params[:start_new_time_tracker].nil?
      start({:issue_id => params[:start_new_time_tracker]})
    else
      redirect_to :back
    end
  rescue StandardError => e
    flash[:error] = e.message
    redirect_to :back
  end

  def update
    @time_tracker = get_current
    @time_tracker.update_attributes!(params[:time_tracker])
    flash[:notice] = l(:update_time_tracker_success)
    unless request.xhr?
      redirect_to :back
    else
      render :partial => 'time_tracker_control_with_flash'
    end
  rescue StandardError => e
    @time_tracker = get_current
    flash[:error] = e.message
    unless request.xhr?
      redirect_to :back
    else
      render :partial => 'time_tracker_control_with_flash'
    end
  end

  protected

  def get_current
    current = TimeTracker.where(:user_id => User.current.id).first
    current.nil? ? TimeTracker.new : current
  end

  private

  def error_handling
    yield
  rescue StandardError => e
    flash[:error] = e.message
    unless request.xhr?
      redirect_to :back
    else
      render :partial => 'flash_messages'
    end
  rescue ActionController::RedirectBackError => e
    flash[:error] = e.message
    unless request.xhr?
      redirect_to :controller => 'tt_overview'
    else
      render :partial => 'flash_messages'
    end
  end

  # following method is necessary to got ajax requests logged_in if REST-API is disabled
  def js_auth
    respond_to do |format|
      format.json { User.current = User.where(:id => session[:user_id]).first }
      format.any {}
    end
  end
  
  private
      def load_issue_status
        @old_status = session[:issue_status] || 0
      end

      def save_issue_status
        session[:issue_status] = @old_status
      end
end
