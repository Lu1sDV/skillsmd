# Fixture: logging a raw client header versus a sanitized request id.

class AccessLog
  def record(request)
    # ruleid: ruby-http-parsing-raw-header-logging
    logger.info("host=#{request.headers['Host']}")
  end

  def record_safe(request)
    # ok: ruby-http-parsing-raw-header-logging
    logger.info("request_id=#{request.request_id}")
  end
end
