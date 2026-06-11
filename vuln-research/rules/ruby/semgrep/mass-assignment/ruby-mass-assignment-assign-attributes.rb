# Fixture for the assign-attributes rule.

def stage_changes(record)
  # ruleid: ruby-mass-assignment-assign-attributes
  record.assign_attributes(params[:record])
end

def stage_changes_safe(record)
  # ok: ruby-mass-assignment-assign-attributes
  record.assign_attributes(params.require(:record).permit(:label))
end

def stage_changes_literal(record)
  # ok: ruby-mass-assignment-assign-attributes
  record.assign_attributes(label: "x")
end
