require "excon"

class Updater
  def fetch_release
    # true positive: an executable downloaded over a plaintext http:// connection
    Excon.get("http://downloads.example.com/installer.exe").body
  end

  def fetch_release_safe
    # negative: same executable fetched over TLS
    Excon.get("https://downloads.example.com/installer.exe").body
  end
end
