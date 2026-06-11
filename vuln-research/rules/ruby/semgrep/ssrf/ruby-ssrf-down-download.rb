# Fixture for the Down.download / Down.open destination check.

def store_remote(host)
  # ruleid: ruby-ssrf-down-download
  Down.download("https://#{host}/image.png")
end

def stream_remote(host)
  # ruleid: ruby-ssrf-down-download
  Down.open("https://#{host}/stream")
end

def store_fixed
  # ok: ruby-ssrf-down-download
  Down.download("https://cdn.example.com/image.png")
end
