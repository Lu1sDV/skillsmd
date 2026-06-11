# Fixture covering Sinatra erb rendering of an interpolated string.

get "/hello" do
  # ruleid: ruby-xss-sinatra-erb-body
  erb("Hello #{params[:name]}")
end

get "/raw" do
  # ruleid: ruby-xss-sinatra-erb-body
  erb(params[:view])
end

get "/page" do
  # ok: ruby-xss-sinatra-erb-body
  erb(:page, locals: { name: params[:name] })
end
