# Public API of the "archiver" gem. Methods here are library inputs:
# their parameters are reachable by any caller of the gem.
module Archiver
  # true positive: the public `name` parameter is concatenated into a shell
  # command string that is then executed -- any consumer of the gem passing
  # untrusted input gets OS command injection.
  def self.compress(name)
    cmd = "tar czf " + name + ".tgz ./data"
    system(cmd)
  end

  # true positive (interpolation form): the public `path` parameter is
  # interpolated into a string later executed by the shell.
  def self.checksum(path)
    system("sha256sum #{path}")
  end

  # negative: fixed command string, no parameter reaches the shell.
  def self.list
    system("tar tzf archive.tgz")
  end
end
