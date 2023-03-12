# frozen_string_literal: true

FactoryBot.define do
  factory :gdrive_item, class: "GDrive::Item" do
    association :gdrive_config, factory: :gdrive_main_config
    kind { "drive" }
    sequence(:external_id) { |i| "xxx#{i}" }
    sequence(:name) { |i| "#{kind.capitalize} #{i}" }
  end
end
