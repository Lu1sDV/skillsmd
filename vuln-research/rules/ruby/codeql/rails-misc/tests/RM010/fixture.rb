# Fixture for RM010: Sidekiq worker called with unfiltered parent IDs (cyclic hierarchy DoS)

module Epics
  class UpdateDatesService
    BATCH_SIZE = 100

    # BAD: parent_ids collected via plain .pluck(:parent_id) with no .where.not(parent_id: descendants)
    # exclusion. If the hierarchy is cyclic, UpdateEpicsDatesWorker re-enqueues infinitely.
    def execute_bad(epics)
      epics.in_batches(of: BATCH_SIZE) do |relation|
        parent_ids = relation.has_parent.distinct.pluck(:parent_id) # BAD: no descendant exclusion
        Epics::UpdateEpicsDatesWorker.perform_async(parent_ids) if parent_ids.any?
      end
    end

    # GOOD: descendants excluded via .where.not before .pluck — cycle broken.
    def execute_good(epics)
      epics.each_batch(of: BATCH_SIZE) do |relation|
        descendants = ::Gitlab::ObjectHierarchy.new(relation).descendants
        parent_ids = relation
          .has_parent
          .where.not(parent_id: descendants)
          .distinct
          .pluck(:parent_id)
        Epics::UpdateEpicsDatesWorker.perform_async(parent_ids) if parent_ids.any?
      end
    end
  end
end

module WorkItems
  class HierarchiesUpdateService
    # BAD: pluck(:work_item_parent_id) without excluding cyclic descendants
    def update_parents_bad(work_items)
      parent_ids = WorkItems::ParentLink.for_children(work_items).pluck(:work_item_parent_id)
      ::WorkItems::UpdateWorker.perform_async(parent_ids) unless parent_ids.empty?
    end

    # GOOD: descendants excluded before pluck
    def update_parents_good(work_items)
      descendants = ::Gitlab::WorkItems::WorkItemHierarchy.new(work_items).descendants
      parent_ids = WorkItems::ParentLink
        .for_children(work_items)
        .where.not(work_item_parent_id: descendants)
        .pluck(:work_item_parent_id)
      ::WorkItems::UpdateWorker.perform_async(parent_ids) unless parent_ids.empty?
    end
  end
end
