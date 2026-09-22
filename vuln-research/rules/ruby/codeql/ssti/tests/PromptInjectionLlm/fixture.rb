# Fixture for PromptInjectionLlm query (RB-QL-0904)
# Tests detection of unsanitized user content embedded in LLM prompts.

# BAD: note content embedded directly into LLM prompt via format with <comment> wrapper,
# no Sanitize.fragment call in this method.
def build_prompt_bad(note)
  notes_content = []
  notes_content << format("<comment>%<note>s</comment>", note: note)
  notes_content
end

# BAD: sprintf variant without sanitization
def build_prompt_sprintf_bad(note)
  format("<comment>%<note>s</comment>", note: note)
end

# GOOD: note is sanitized with Sanitize.fragment before embedding
def build_prompt_good(note)
  sanitized = Sanitize.fragment(note, Sanitize::Config::RELAXED)
  format("<comment>%<note>s</comment>", note: sanitized)
end

# GOOD: format call does not use <comment> wrapper (unrelated prompt building)
def build_other_prompt(value)
  format("Answer: %<value>s", value: value)
end
