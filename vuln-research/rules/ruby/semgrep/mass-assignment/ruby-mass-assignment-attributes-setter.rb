# Fixture for the attributes-setter rule.

def apply(record)
  # ruleid: ruby-mass-assignment-attributes-setter
  record.attributes = params[:record]
  record.save
end

def apply_safe(record)
  # ok: ruby-mass-assignment-attributes-setter
  record.attributes = params.require(:record).permit(:title)
  record.save
end
