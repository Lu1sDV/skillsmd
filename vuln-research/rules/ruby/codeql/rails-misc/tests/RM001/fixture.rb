# frozen_string_literal: true

# BAD: name is validated for presence but has no length constraint — unbounded input
class Board < ApplicationRecord
  belongs_to :project

  validates :name, presence: true   # BAD: missing length: { maximum: N }
end

# GOOD: name is validated for presence AND has a separate length constraint
class Runner < ApplicationRecord
  validates :name, presence: true, length: { maximum: 256 }  # GOOD: length is present in same call
end

# GOOD: separate validates call with length
class Pipeline < ApplicationRecord
  validates :ref, presence: true, length: { maximum: 300 }  # GOOD: length inline
end

# GOOD: presence validated separately, but a length validator also exists for the field
class WebHook < ApplicationRecord
  validates :url, presence: true   # GOOD: length validator below covers :url
  validates :url, length: { maximum: 8192 }
end
