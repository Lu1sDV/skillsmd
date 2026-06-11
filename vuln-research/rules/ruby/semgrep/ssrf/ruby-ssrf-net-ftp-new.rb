# Fixture for the Net::FTP.new host check.

def ftp_pull(host)
  # ruleid: ruby-ssrf-net-ftp-new
  Net::FTP.new("#{host}")
end

def ftp_pull_fixed
  # ok: ruby-ssrf-net-ftp-new
  Net::FTP.new("files.example.com")
end
