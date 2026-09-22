-- Idempotent loader for the bypasses catalogue.
-- Re-applies cleanly: upserts by id, leaves unrelated rows alone.
-- Run after schema.sql. Set :json_path to the absolute path of bypasses.json.

INSERT INTO bypasses (id, defense_type, family, description, applies_when, applies_when_tags, examples)
SELECT id, defense_type, family, description, applies_when, applies_when_tags, examples
FROM read_json_auto(getvariable('json_path'))
ON CONFLICT (id) DO UPDATE SET
  defense_type      = EXCLUDED.defense_type,
  family            = EXCLUDED.family,
  description       = EXCLUDED.description,
  applies_when      = EXCLUDED.applies_when,
  applies_when_tags = EXCLUDED.applies_when_tags,
  examples          = EXCLUDED.examples;
