# Fixture for Sinatra redirect with tainted destinations.

class App < Sinatra::Base
  get "/go" do
    # ruleid: ruby-open-redirect-sinatra-redirect
    redirect params[:url]
  end

  get "/jump" do
    # ruleid: ruby-open-redirect-sinatra-redirect
    redirect "#{params[:next]}"
  end

  get "/home" do
    # ok: ruby-open-redirect-sinatra-redirect
    redirect "/dashboard"
  end
end
