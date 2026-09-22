# BAD: model validates presence but has no length cap anywhere in the class
class AbuseReport < ApplicationRecord
  validates :reporter, presence: true
  validates :message, presence: true
  validates :category, presence: true
end

# GOOD: model validates presence AND has at least one length cap
class SafeReport < ApplicationRecord
  validates :reporter, presence: true
  validates :message, presence: true, length: { maximum: 2048 }
  validates :category, presence: true
end

# GOOD: model has no validates at all — nothing to flag
class PlainModel < ApplicationRecord
end

# GOOD: model is not an ActiveRecord subclass — ignore it
class SomePoro
  validates :title, presence: true
end
