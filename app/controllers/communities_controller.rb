# frozen_string_literal: true

class CommunitiesController < ApplicationController
  skip_before_action :require_current_community
  decorates_assigned :communities

  def index
    authorize(sample_community)
    @communities = Utils::CommunitySummarizer.new.communities(policy_scope(Community))
  end

  private

  def sample_community
    Community.new
  end
end
