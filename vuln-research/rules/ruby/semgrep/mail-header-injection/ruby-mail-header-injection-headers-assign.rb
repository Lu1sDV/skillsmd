# Fixture for the direct mail header assignment detector.

class CampaignMailer < ApplicationMailer
  def blast
    # ruleid: ruby-mail-header-injection-headers-assign
    headers["X-Campaign"] = params[:campaign]
  end

  def tag
    # ruleid: ruby-mail-header-injection-headers-assign
    headers["X-Tag"] = "run-#{params[:run]}"
  end

  def blast_safe
    # ok: ruby-mail-header-injection-headers-assign
    headers["X-Campaign"] = campaign.slug
  end
end
