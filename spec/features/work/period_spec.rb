require "rails_helper"

feature "periods", js: true do
  let(:actor) { create(:work_coordinator) }
  let!(:period1) do
    create(:work_period,
      name: "Foo",
      starts_on: "2017-01-01",
      ends_on: "2017-04-30",
      phase: "archived")
  end
  let!(:period2) do
    create(:work_period,
      name: "Bar",
      starts_on: "2017-05-01",
      ends_on: "2017-08-31",
      phase: "active")
  end
  let!(:period3) do
    create(:work_period,
      name: "Baz",
      starts_on: "2017-09-01",
      ends_on: "2017-12-31",
      phase: "draft")
  end
  let!(:user1) { create(:user, first_name: "Jane", last_name: "Picard") }
  let!(:user2) { create(:user, first_name: "Churl", last_name: "Rox") }
  let!(:user3) { create(:user, :child, first_name: "Kid", last_name: "Knelt") }

  around { |ex| with_user_home_subdomain(actor) { ex.run } }

  before do
    login_as(actor, scope: :user)
  end

  scenario "index" do
    visit(work_periods_path)
    expect(page).to have_title("Work Periods")
    expect(page).to have_css("table.index tr", count: 4) # Header plus two rows
    expect(page).to have_css("table.index tr td.name", text: "Foo")
  end

  scenario "create, update" do
    visit(work_periods_path)
    click_on("Create Period")

    expect(page).to have_select("Jane Picard", selected: "Full Share")
    expect(page).to have_select("Churl Rox", selected: "Full Share")
    expect(page).to have_select("Kid Knelt", selected: "No Share")
    fill_in("Name", with: "Qux")
    select("Open", from: "Phase")
    enter_date("2018-01-01", into: "work_period_starts_on")
    enter_date("2018-02-01", into: "work_period_ends_on")
    select("Full Share", from: "Jane Picard")
    select("Half Share", from: "Churl Rox")
    click_on("Create Period")

    create(:user, first_name: "Blep", last_name: "Cruller")

    click_on("Qux")
    expect(page).to have_select("Churl Rox", selected: "Half Share")
    expect(page).to have_select("Blep Cruller", selected: "")
    select("Half Share", from: "Blep Cruller")
    click_on("Update Period")

    click_on("Qux")
    expect(page).to have_select("Blep Cruller", selected: "Half Share")
  end

  scenario "destroy" do
    visit(work_periods_path)
    click_on("Baz")
    click_on("Delete")
    expect(page).to have_content("deleted successfully")
  end
end
