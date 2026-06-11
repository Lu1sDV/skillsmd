# Fixture for the IO.write / IO.binwrite path-injection rule.

def io_store(data)
  # ruleid: ruby-path-traversal-io-write
  IO.write(params[:dest], data)
end

def io_store_named(data)
  # ruleid: ruby-path-traversal-io-write
  IO.binwrite("/srv/out/#{params[:name]}", data)
end

def io_store_fixed(data)
  # ok: ruby-path-traversal-io-write
  IO.write("/srv/out/result.txt", data)
end
