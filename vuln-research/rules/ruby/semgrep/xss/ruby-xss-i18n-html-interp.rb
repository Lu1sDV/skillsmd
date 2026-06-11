# Fixture covering _html translation keys with unsafe interpolation.

def greeting(name)
  # ruleid: ruby-xss-i18n-html-interp
  t("welcome_html", user: raw(name))
end

def notice
  # ruleid: ruby-xss-i18n-html-interp
  I18n.t("flash.notice_html", body: raw(params[:body]))
end

def plain_greeting(name)
  # ok: ruby-xss-i18n-html-interp
  t("welcome", user: name)
end
