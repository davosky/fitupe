class ZoningPolicy < ApplicationPolicy
  def index? = admin_or_manager?
  def show? = admin_or_manager?
  def create? = admin_or_manager?
  def update? = admin_or_manager?
  def destroy? = admin_or_manager?

  class Scope < ApplicationPolicy::Scope
    def resolve
      user.admin? || user.manager? ? scope.all : scope.none
    end
  end

  private

  def admin_or_manager?
    user.admin? || user.manager?
  end
end
