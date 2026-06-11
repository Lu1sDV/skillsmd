# Fixture for the update-columns rule.

def force_columns(record)
  # ruleid: ruby-mass-assignment-update-columns
  record.update_columns(params[:record])
end

def force_unsafe(record)
  # ruleid: ruby-mass-assignment-update-columns
  record.update_columns(params.to_unsafe_h)
end

def force_columns_safe(record)
  # ok: ruby-mass-assignment-update-columns
  record.update_columns(updated_at: Time.now)
end
