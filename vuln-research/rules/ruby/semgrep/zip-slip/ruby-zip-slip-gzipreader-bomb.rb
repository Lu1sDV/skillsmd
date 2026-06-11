require "zlib"

def inflate_all(path)
  # ruleid: ruby-zip-slip-gzipreader-bomb
  Zlib::GzipReader.open(path).read
end

def inflate_bounded(path, limit = 50_000_000)
  out = +""
  Zlib::GzipReader.open(path) do |gz|
    # ok: ruby-zip-slip-gzipreader-bomb
    while (chunk = gz.read(64 * 1024))
      out << chunk
      raise "too big" if out.bytesize > limit
    end
  end
  out
end
