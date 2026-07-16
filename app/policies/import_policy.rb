class ImportPolicy < ApplicationPolicy
  def manage?
    user.admin? || user.manager?
  end
end
