# frozen_string_literal: true

# ---------------------------------------------------------------------------
# BAD cases — AR finder result used in response/serializer without .limit()
# ---------------------------------------------------------------------------

module NotesActions
  # BAD: notes_finder.execute result goes to render via merge_resource_events
  # without any .limit() call in this method
  def gather_all_notes
    notes = merge_resource_events(notes_finder.execute)   # BAD: no .limit()
    render json: notes
  end

  # BAD: .all passed straight to render
  def index_all
    @records = Widget.all                                 # BAD: no .limit()
    render json: @records
  end

  # BAD: .where used without limit, result serialized
  def index_filtered
    items = Report.where(active: true)                    # BAD: no .limit()
    render json: items.to_json
  end
end

# ---------------------------------------------------------------------------
# GOOD cases — guarded with .limit() or .paginate / no response sink present
# ---------------------------------------------------------------------------

module SafeNotesActions
  # GOOD: .limit() is present before rendering
  def gather_all_notes_safe
    notes = notes_finder.execute.limit(100)               # GOOD: limit applied
    render json: notes
  end

  # GOOD: paginate guard present
  def index_paginated
    @records = Widget.all.paginate(page: params[:page])   # GOOD: paginate present
    render json: @records
  end

  # GOOD: .limit in the callable (called via a separate chain)
  def index_with_limit
    items = Report.where(active: true).limit(50)          # GOOD: limit applied
    render json: items
  end

  # GOOD: finder called but no response sink in this method (pure data helper)
  def load_data_only
    Widget.all
  end
end
