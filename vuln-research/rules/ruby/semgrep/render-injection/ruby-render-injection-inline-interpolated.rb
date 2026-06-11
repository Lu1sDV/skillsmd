# Fixture for render inline: assembled from request input.

class GreetController < ApplicationController
  def hello
    # ruleid: ruby-render-injection-inline-interpolated
    render inline: "Hello #{params[:name]}"
  end

  def safe_hello
    # ok: ruby-render-injection-inline-interpolated
    render inline: "Hello <%= @name %>", locals: { name: params[:name] }
  end
end
