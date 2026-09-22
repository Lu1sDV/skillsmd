# Fixture for AdminBareAdminCheckWithoutMode

module Admin
  class SessionsController
    # BAD: uses .admin? as access guard without can_access_admin_area? or admin_mode?
    def user_is_admin!
      render_404 unless current_user.admin?
    end

    # GOOD: uses can_access_admin_area? — safe, respects admin mode
    def user_can_access_admin!
      render_404 unless current_user.can_access_admin_area?
    end

    # GOOD: has paired admin_mode? check in same method
    def user_is_admin_with_mode!
      render_404 unless current_user.admin? && current_user_mode.admin_mode?
    end
  end
end
