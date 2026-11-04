## ULTRA-specific execution ledger

ULTRA is **DEEP plus** a comprehensive instruction ledger. First assemble every instruction from the selected skill, its shared protocol, task/request, relevant specialist skills, repository guidance and applicable tool constraints. Split compound instructions into independently testable obligations. Record: `Order/ID | Obligation | Owner | Status | Evidence/reason`.

Statuses: `pending`, `checked`, `not applicable`, `blocked`. Each domain/risk/holistic worker processes its **own** assigned obligations **sequentially**, recording an outcome and evidence for each. Workers continue **in parallel** across ownership boundaries. The coordinator then reconciles the combined instruction ledger **sequentially**, resolves contradictions, reviews blockers and missing evidence, and only then emits the final tables. Do not conflate a completed ledger entry with a successful verification: `blocked` is accounted for but not `checked`.

The ledger must distinguish **requested versus completed** independent reviews and outstanding method limitations. No unassessed `pending` item may be silently declared complete. When a tool or specialist is unavailable, record `blocked` and explain in the final summary. The ledger itself is internal unless the user explicitly asks for it.
