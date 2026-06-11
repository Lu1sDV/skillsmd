# Fixture for translation store poisoning.

class TranslationsController < ApplicationController
  def create
    # ruleid: ruby-rails-misc-i18n-store-translations-tainted
    I18n.backend.store_translations(:en, params[:translations])
  end

  def create_scoped
    # ruleid: ruby-rails-misc-i18n-store-translations-tainted
    I18n.backend.store_translations(:en, params[:data], escape: false)
  end

  def seed_safe
    data = YAML.safe_load(File.read(Rails.root.join("config/locales/en.yml")))
    # ok: ruby-rails-misc-i18n-store-translations-tainted
    I18n.backend.store_translations(:en, data)
  end
end
