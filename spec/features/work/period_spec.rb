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

    # Fill in basic attribs
    select("Open", from: "Phase")
    pick_date(".work_period_starts_on", day: 15)
    pick_date(".work_period_ends_on", day: 20)
    fill_in("Name", with: "Qux")

    # Set quota attrib and choose share values
    expect(page).not_to have_content("Pick Type")
    expect(page).not_to have_select("Jane Picard")
    select("By Household", from: "Quota")
    expect(page).to have_select("Jane Picard", selected: "Full Share")
    expect(page).to have_select("Churl Rox", selected: "Full Share")
    expect(page).to have_select("Kid Knelt", selected: "No Share")
    select("Full Share", from: "Jane Picard")
    select("½ Share", from: "Churl Rox")

    # Set auto open time, pick type, and staggering options
    expect(page).not_to have_content("Round Duration")
    pick_datetime(".work_period_auto_open_time", day: 1, hour: 12)
    select("Groups of workers take turns choosing", from: "Pick Type")
    fill_in("Max. Rounds per Worker", with: 2)
    fill_in("Workers per Group", with: 5)
    select("3 minutes", from: "Round Duration")

    click_button("Save")

    # Simulate user creation after period is created.
    create(:user, first_name: "Blep", last_name: "Cruller")

    click_on("Qux")
    expect(page).to have_select("Churl Rox", selected: "½ Share")
    expect(page).to have_select("Blep Cruller", selected: "")
    expect(page).to have_select("Pick Type", selected: "Groups of workers take turns choosing")
    expect(page).to have_select("Round Duration", selected: "3 minutes")
    select("½ Share", from: "Blep Cruller")
    click_button("Save")

    click_on("Qux")
    expect(page).to have_select("Blep Cruller", selected: "½ Share")
  end

  scenario "destroy" do
    visit(work_periods_path)
    click_on("Baz")
    click_on("Delete")
    expect(page).to have_content("deleted successfully")
  end
end
