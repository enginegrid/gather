# frozen_string_literal: true

require "rails_helper"

describe Calendars::System::CommunityMealsCalendar do
  include_context "system calendars"
  include_context "meals system calendars"

  let(:calendar) { create(:community_meals_calendar) }

  it "returns correct event attribs" do
    attribs = [{
      name: "[No Menu] ✓",
      starts_at: meal1.served_at,
      ends_at: meal1.served_at + 1.hour,
      meal_id: meal1.id,
      creator_id: meal1.creator_id,
      linkable: meal1,
      uid: "cmty_meals_#{meal1.id}",
    }, {
      name: "Meal2",
      starts_at: meal2.served_at,
      ends_at: meal2.served_at + 1.hour,
      meal_id: meal2.id,
      creator_id: meal2.creator_id,
      linkable: meal2,
      uid: "cmty_meals_#{meal2.id}",
    }]
    events = calendar.events_between(full_range, actor: actor)
    expect_events(events, *attribs)
  end

  it "returns correct events inside tighter range" do
    range = (meal1.served_at - 5.minutes)..(meal1.served_at + 1.hour)
    events = calendar.events_between(range, actor: actor)
    expect_events(events, name: "[No Menu] ✓")
    range = (meal2.served_at + 15.minutes)..(meal2.served_at + 30.minutes)
    events = calendar.events_between(range, actor: actor)
    expect_events(events, name: "Meal2")
  end

  it "respects policy scope" do
    null_scope = double(resolve: Meals::Meal.none)
    expect(Meals::MealPolicy::Scope).to receive(:new).and_return(null_scope)
    expect(calendar.events_between(full_range, actor: actor)).to be_empty
  end
end
