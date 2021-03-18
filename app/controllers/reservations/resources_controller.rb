# frozen_string_literal: true

module Calendars
  class CalendarsController < ApplicationController
    include Destructible

    decorates_assigned :calendar, :calendars
    helper_method :sample_calendar

    before_action -> { nav_context(:calendars, :calendars) }

    def index
      authorize(sample_calendar)
      @calendars = policy_scope(Calendar).with_event_counts
        .in_community(current_community).deactivated_last.by_name
    end

    def new
      @calendar = sample_calendar
      authorize(@calendar)
      prep_form_vars
    end

    def edit
      @calendar = Calendar.find(params[:id])
      authorize(@calendar)
      prep_form_vars
    end

    def create
      @calendar = sample_calendar
      @calendar.assign_attributes(calendar_params)
      authorize(@calendar)
      if @calendar.save
        flash[:success] = "Calendar created successfully."
        redirect_to(calendars_path)
      else
        prep_form_vars
        render(:new)
      end
    end

    def update
      @calendar = Calendar.find(params[:id])
      authorize(@calendar)
      if @calendar.update(calendar_params)
        flash[:success] = "Calendar updated successfully."
        redirect_to(calendars_path)
      else
        prep_form_vars
        render(:edit)
      end
    end

    protected

    def klass
      Calendar
    end

    private

    def sample_calendar
      @sample_calendar ||= Calendar.new(community: current_community)
    end

    def prep_form_vars
      @max_photo_size = Calendar.validators_on(:photo).detect { |v| v.is_a?(FileSizeValidator) }.options[:max]
    end

    # Pundit built-in helper doesn't work due to namespacing
    def calendar_params
      params.require(:calendars_calendar).permit(policy(@calendar).permitted_attributes)
    end
  end
end
