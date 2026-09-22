# Fixture for HtmlSafetyValidatorMissingOnModel

module Achievements
  class Achievement < ApplicationRecord
    # BAD: validates :name with standard validators but no html_safety: true
    validates :name,
      presence: true,
      length: { maximum: 255 },
      uniqueness: { case_sensitive: false }

    # BAD: validates :description with only length — no html_safety: true
    validates :description, length: { maximum: 1024 }

    def unique_users
      users.distinct
    end
  end

  class SafeAchievement < ApplicationRecord
    # GOOD: html_safety: true is present on :name
    validates :name,
      presence: true,
      length: { maximum: 255 },
      uniqueness: { case_sensitive: false },
      html_safety: true

    # GOOD: html_safety: true is present on :description
    validates :description, length: { maximum: 1024 }, html_safety: true
  end

  class IdModel < ApplicationRecord
    # GOOD: :id is not a human-facing string attribute — should not flag
    validates :id, presence: true, uniqueness: true
  end

  class CountModel < ApplicationRecord
    # GOOD: :count is not in the human-facing attribute list — should not flag
    validates :count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  end
end
