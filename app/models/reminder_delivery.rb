# frozen_string_literal: true

# Tracks the delivery of a given reminder for a given Shift, in order to prevent duplicate deliveries.
class ReminderDelivery < ApplicationRecord
  TOO_OLD = 1.hour

  acts_as_tenant :cluster

  belongs_to :reminder, class_name: "Reminder", inverse_of: :deliveries

  # These are subclass-specific but they need to be up here so we can eager load them.
  belongs_to :shift, class_name: "Work::Shift", inverse_of: :reminder_deliveries
  belongs_to :meal, inverse_of: :reminder_deliveries

  delegate :abs_time, :rel_magnitude, :rel_sign, :abs_time?, :rel_days?, to: :reminder
  delegate :community, :assignments, to: :event

  def deliver!
    assignments.each { |assignment| send_mail(assignment) }
    destroy
  end

  # Calculates (or recaculates) deliver_at.
  # If not persisted: saves only if deliver_at in future.
  # If persisted: saves if deliver_at changes; destroys if deliver_at in past.
  def calculate_and_save
    compute_deliver_at
    if new_record?
      save! unless too_old?
    elsif too_old?
      destroy
    elsif will_save_change_to_deliver_at?
      save!
    end
  end

  protected

  def starts_at
    event.starts_at
  end

  private

  def too_old?
    deliver_at < Time.current - TOO_OLD
  end

  def compute_deliver_at
    self.deliver_at =
      if abs_time?
        abs_time
      elsif rel_days?
        starts_at.midnight + rel_sign * rel_magnitude.days + Settings.reminders.time_of_day.hours
      else
        starts_at + rel_sign * rel_magnitude.hours
      end
  end
end
