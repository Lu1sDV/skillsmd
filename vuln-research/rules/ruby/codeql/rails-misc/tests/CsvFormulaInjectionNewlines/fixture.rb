# Fixture for CsvFormulaInjectionNewlines

class VulnerabilityExportService
  # BAD: CsvBuilder.new without replace_newlines: true — embedded newlines
  # in cell values can break CSV row boundaries and inject formula characters.
  def csv_builder
    @csv_builder ||= CsvBuilder.new(vulnerabilities, mapping, preloads)
  end

  # GOOD: replace_newlines: true sanitizes newlines before export.
  def safe_csv_builder
    @csv_builder ||= CsvBuilder.new(vulnerabilities, mapping, preloads, replace_newlines: true)
  end
end
