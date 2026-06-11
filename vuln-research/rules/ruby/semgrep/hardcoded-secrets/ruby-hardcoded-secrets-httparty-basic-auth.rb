# Fixture for hardcoded HTTParty basic auth options.
# Flagged call inlines the credentials; the safe call sources them from the environment.

class WeatherApi
  include HTTParty

  def forecast
    # ruleid: ruby-hardcoded-secrets-httparty-basic-auth
    self.class.get("/forecast", basic_auth: {username: "weather-svc", password: "Pl41nWeatherPass"})
  end

  def forecast_safe
    # ok: ruby-hardcoded-secrets-httparty-basic-auth
    self.class.get("/forecast", basic_auth: {username: ENV["WEATHER_USER"], password: ENV["WEATHER_PASS"]})
  end
end
