# BAD: per_page taken directly from params and passed to keyset_paginate without a cap
class DiscussionsListService
  def paginator
    issuable
      .discussion_root_note_ids
      .keyset_paginate(cursor: params[:cursor], per_page: params[:per_page].to_i) # BAD: unbounded
  end
end

# BAD: per_page passed as raw params subscript (no .to_i conversion either)
class AnotherService
  def results
    records.keyset_paginate(per_page: params[:per_page]) # BAD: unbounded
  end
end

# BAD: kaminari-style paginate with raw per_page from params
class ItemsController
  def index
    @items = Item.all.paginate(page: params[:page], per_page: params[:per_page].to_i) # BAD: unbounded
  end
end

# GOOD: per_page capped with [val, MAX].min before being passed
class SafeDiscussionsService
  MAX_PER_PAGE = 100

  def paginator
    per_page = [params[:per_page].to_i, MAX_PER_PAGE].min
    per_page = Kaminari.config.default_per_page if per_page <= 0
    issuable
      .discussion_root_note_ids
      .keyset_paginate(cursor: params[:cursor], per_page: per_page) # GOOD: capped variable
  end
end

# GOOD: per_page is a hardcoded literal, not from params
class StaticPaginationService
  def paginator
    records.keyset_paginate(per_page: 25) # GOOD: literal constant
  end
end
