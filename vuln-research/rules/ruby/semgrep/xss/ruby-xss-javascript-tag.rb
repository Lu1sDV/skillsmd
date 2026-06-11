# Fixture covering javascript_tag inline script generation.

def init(user_id)
  # ruleid: ruby-xss-javascript-tag
  javascript_tag("var uid = #{user_id};")
end

def init_param
  # ruleid: ruby-xss-javascript-tag
  javascript_tag(params[:bootstrap])
end

def static_init
  # ok: ruby-xss-javascript-tag
  javascript_tag("console.log('ready')")
end
