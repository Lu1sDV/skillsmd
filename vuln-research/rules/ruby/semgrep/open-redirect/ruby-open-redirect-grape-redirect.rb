# Fixture for Grape API redirect with tainted destinations.

class API < Grape::API
  get "/out" do
    # ruleid: ruby-open-redirect-grape-redirect
    redirect params[:to]
  end

  get "/forward" do
    # ruleid: ruby-open-redirect-grape-redirect
    redirect "#{params[:dest]}"
  end

  get "/inside" do
    # ok: ruby-open-redirect-grape-redirect
    redirect "/v1/status"
  end
end
