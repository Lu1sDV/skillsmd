require "zlib"

def expand(blob)
  # ruleid: ruby-zip-slip-inflate-bomb
  Zlib::Inflate.inflate(blob)
end

def expand_bounded(blob, limit = 20_000_000)
  zstream = Zlib::Inflate.new
  out = +""
  zstream.inflate(blob) do |chunk|
    out << chunk
    raise "bomb" if out.bytesize > limit
  end
  # ok: ruby-zip-slip-inflate-bomb
  zstream.finish
  out
end
