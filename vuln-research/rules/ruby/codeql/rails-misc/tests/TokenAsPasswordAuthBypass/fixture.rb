# frozen_string_literal: true

module Gitlab
  module Auth
    # BAD: performs LDAP/DB password auth without checking if the password is a token first
    def user_with_password_for_git_bad(login, password)
      user = find_with_user_password(login, password) # BAD: no token? guard
      return unless user
      user
    end

    # GOOD: short-circuits before password auth when password is a token
    def user_with_password_for_git_good(login, password)
      return if password.present? && Authn::AgnosticTokenIdentifier.token?(password) # GOOD: token guard
      user = find_with_user_password(login, password)
      return unless user
      user
    end
  end
end
