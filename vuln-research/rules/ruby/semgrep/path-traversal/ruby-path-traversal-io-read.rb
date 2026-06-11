# Fixture for the IO.read / IO.binread path-injection rule.

def io_dump
  # ruleid: ruby-path-traversal-io-read
  IO.read(params[:path])
end

def io_named
  # ruleid: ruby-path-traversal-io-read
  IO.binread("/srv/files/#{params[:id]}")
end

def io_fixed
  # ok: ruby-path-traversal-io-read
  IO.read("/srv/files/index.dat")
end
