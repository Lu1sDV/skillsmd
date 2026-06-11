# Fixture for verbose SQL query logging.

Rails.application.configure do
  # ruleid: ruby-rails-misc-verbose-query-logs
  config.active_record.verbose_query_logs = true

  # ok: ruby-rails-misc-verbose-query-logs
  config.active_record.verbose_query_logs = false
end
