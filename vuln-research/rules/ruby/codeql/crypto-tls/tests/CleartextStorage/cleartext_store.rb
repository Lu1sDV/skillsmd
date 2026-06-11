class Credentials
  # True positive: a password is written to disk without encryption.
  def persist(password)
    File.write("/tmp/creds.txt", password)
  end

  # Safe: writing a non-sensitive build number to disk leaks no secret.
  def persist_version(build_number)
    File.write("/tmp/version.txt", build_number)
  end
end
