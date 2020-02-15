# frozen_string_literal: true

module Groups
  module Mailman
    # A membership of a user in a mailman list. Ephemeral model used during sync.
    # Different, but computed from, from a membership in a group, which is persisted.
    class ListMembership
      include ActiveModel::Model

      attr_accessor :id, :mailman_user, :list_id, :role
      delegate :email, to: :mailman_user

      def user_remote_id
        mailman_user.remote_id
      end

      def ==(other)
        mailman_user == other.mailman_user && list_id == other.list_id
      end

      def eql?(other)
        self == other
      end

      def hash
        [mailman_user, list_id].hash
      end
    end
  end
end
