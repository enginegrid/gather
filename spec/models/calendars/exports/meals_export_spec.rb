# frozen_string_literal: true

require "rails_helper"

describe "meals exports" do
  include_context "calendar exports"

  let(:calendar) { create(:calendar, name: "Dining Room") }
  let(:meal1_time) { Time.current.midnight + 18.hours }
  let!(:meal1) do
    create(:meal, :with_menu, title: "Meal1", head_cook: user,
                              served_at: meal1_time, calendars: [calendar])
  end
  let!(:meal2) do
    create(:meal, :with_menu, title: "Meal2", served_at: Time.current + 2.days)
  end
  let!(:meal3) do
    create(:meal, :with_menu, title: "Other Cmty Meal", community: communityB,
                              served_at: Time.current + 3.days,
                              communities: [meal1.community, communityB])
  end
  let!(:cancelled_meal) do
    create(:meal, :cancelled)
  end
  let!(:signup1) do
    create(:meal_signup, meal: meal1, household: user.household, comments: "Foo\nBar", diner_counts: [2])
  end
  let!(:signup2) do
    create(:meal_signup, meal: cancelled_meal, household: user.household, diner_counts: [2])
  end

  context "your meals" do
    subject(:ical_data) { Calendars::Exports::YourMealsExport.new(user: user).generate }

    it do
      expect_calendar_name("Meals You're Attending")
      expect_events(
        summary: "Meal1",
        description: /By #{user.name}\s+2 diners from your household\s{49}Signup comments:\s+Foo\s+Bar/,
        location: "#{user.community_abbrv} Dining Room",
        "DTSTART;TZID=Etc/UTC" => meal1_time.to_s(:no_sep),
        "DTEND;TZID=Etc/UTC" => (meal1_time + 1.hour).to_s(:no_sep)
      )
      expect(ical_data).not_to match("Meal2")
      expect(ical_data).not_to match("Other Cmty Meal")
    end
  end

  context "community meals (personalized)" do
    subject(:ical_data) { Calendars::Exports::CommunityMealsExport.new(user: user).generate }

    it do
      expect_calendar_name("#{user.community.name} Meals")
      attribs = [{
        summary: "Meal1",
        description: /By #{user.name}\s+2 diners from your household/ # Personalized description
      }, {
        summary: "Meal2"
      }]
      expect_events(*attribs)
      expect(ical_data).not_to match("Other Cmty Meal")
    end
  end

  context "community meals (not personalized)" do
    subject(:ical_data) { Calendars::Exports::CommunityMealsExport.new(community: community).generate }

    it do
      expect_calendar_name("#{user.community.name} Meals")
      attribs = [{
        summary: "Meal1",
        description: "By #{user.name}" # Non-personalized description
      }, {
        summary: "Meal2"
      }]
      expect_events(*attribs)
      expect(ical_data).not_to match("Other Cmty Meal")
    end
  end

  context "all meals (personalized)" do
    subject(:ical_data) { Calendars::Exports::AllMealsExport.new(user: user).generate }

    it do
      expect_calendar_name("All Meals")
      attribs = [{
        summary: "Meal1",
        description: /By #{user.name}\s+2 diners from your household/ # Personalized description
      }, {
        summary: "Meal2"
      }, {
        summary: "Other Cmty Meal"
      }]
      expect_events(*attribs)
    end
  end

  context "all meals (not personalized)" do
    subject(:ical_data) { Calendars::Exports::AllMealsExport.new(community: community).generate }

    it do
      expect_calendar_name("All Meals")
      attribs = [{
        summary: "Meal1",
        description: "By #{user.name}" # Non-personalized description
      }, {
        summary: "Meal2"
      }, {
        summary: "Other Cmty Meal"
      }]
      expect_events(*attribs)
    end
  end
end
