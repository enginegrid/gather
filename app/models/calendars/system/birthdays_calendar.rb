# frozen_string_literal: true

module Calendars
  module System
    # Returns people's birthdays
    class BirthdaysCalendar < UserAnniversariesCalendar
      def events_between(range, user:)
        super(range, user: user)
      end

      protected

      def attrib
        :birthdate
      end

      def emoji
        "🎂"
      end
    end
  end
end
