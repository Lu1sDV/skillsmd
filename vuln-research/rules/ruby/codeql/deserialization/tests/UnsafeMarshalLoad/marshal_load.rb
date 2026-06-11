class SessionsController < ApplicationController
  def restore
    blob = params[:state]
    # Attacker-controlled data reaches Marshal.load -> object instantiation / RCE.
    obj = Marshal.load(blob)
    render plain: obj.inspect
  end

  def safe_restore
    # Constant trusted data, no taint flow here.
    obj = Marshal.load(File.binread("/etc/app/trusted.bin"))
    render plain: obj.inspect
  end
end
