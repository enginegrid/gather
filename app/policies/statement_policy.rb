class StatementPolicy < ApplicationPolicy
  include Accountish

  alias_method :statement, :record

  def index?
    admin_or_biller?
  end

  def generate?
    admin_or_biller?
  end

  def show?
    same_community_admin_or_biller? || account_owner?
  end
end