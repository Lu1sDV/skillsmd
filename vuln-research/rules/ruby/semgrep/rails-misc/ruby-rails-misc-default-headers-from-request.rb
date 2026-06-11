# Fixture for tainted response header assignment.

class ProxyController < ApplicationController
  def forward
    # ruleid: ruby-rails-misc-default-headers-from-request
    response.headers["X-Origin"] = params[:origin]
  end

  def reflect
    # ruleid: ruby-rails-misc-default-headers-from-request
    response.set_header("X-Trace", params[:trace])
  end

  def forward_safe
    allowed = { "us" => "us-east", "eu" => "eu-west" }
    # ok: ruby-rails-misc-default-headers-from-request
    response.headers["X-Region"] = allowed.fetch(params[:region], "us-east")
  end
end
