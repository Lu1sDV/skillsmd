#!/usr/bin/env ruby
# frozen_string_literal: true
# Walk authored Semgrep + CodeQL rule files and emit manifest.json — an index
# over every rule with its vr-id, category, CWE, citation, and validation state.
#
# Usage: ruby tools/gen_manifest.rb [--check]
#   (default) writes manifest.json
#   --check   prints summary, exits 1 if any rule is missing required metadata
require "json"
require "yaml"

ROOT = File.expand_path("..", __dir__)   # rules/ruby
check_only = ARGV.include?("--check")

entries = []
problems = []

# --- Semgrep rules ---
Dir.glob(File.join(ROOT, "semgrep", "**", "*.yaml")).sort.each do |path|
  rel = path.sub("#{ROOT}/", "")
  doc = YAML.safe_load(File.read(path), aliases: true) rescue nil
  next unless doc && doc["rules"]
  doc["rules"].each do |r|
    md = r["metadata"] || {}
    test_rb = path.sub(/\.yaml$/, ".rb")
    e = {
      "engine" => "semgrep", "file" => rel, "rule_id" => r["id"],
      "vr_id" => md["vr-id"], "category" => md["category"],
      "cwe" => md["cwe"], "confidence" => md["confidence"],
      "citation" => md["source-citation"], "tier" => md["tier"],
      "has_test" => File.exist?(test_rb),
      "validated" => md["validated"]
    }
    %w[vr-id category source-citation].each do |k|
      problems << "#{rel}/#{r["id"]}: missing metadata.#{k}" if md[k].nil? || md[k].to_s.empty?
    end
    problems << "#{rel}/#{r["id"]}: missing co-located test #{File.basename(test_rb)}" unless e["has_test"]
    entries << e
  end
end

# --- CodeQL queries (skip test fixtures) ---
Dir.glob(File.join(ROOT, "codeql", "**", "*.ql")).sort.each do |path|
  next if path.include?("/tests/")
  rel = path.sub("#{ROOT}/", "")
  src = File.read(path)
  meta = {}
  src.scan(/@(\S+)\s+([^\n*]+)/) { |k, v| meta[k] = v.strip }
  # category = the directory under codeql/ (e.g. codeql/xss/Foo.ql -> "xss")
  category = rel.split("/")[1]
  # CWEs = every external/cwe/cwe-NNN tag, normalized to "CWE-NNN"
  cwes = src.scan(%r{cwe-(\d+)}i).flatten.map { |n| "CWE-#{n}" }.uniq
  test_dir = File.join(File.dirname(path), "tests", File.basename(path, ".ql"))
  e = {
    "engine" => "codeql", "file" => rel, "rule_id" => meta["id"],
    "vr_id" => meta["vr-id"], "category" => category,
    "cwe" => cwes, "precision" => meta["precision"],
    "citation" => meta["source-citation"], "has_test" => Dir.exist?(test_dir)
  }
  %w[id vr-id source-citation].each do |k|
    problems << "#{rel}: missing @#{k}" if meta[k].nil? || meta[k].to_s.empty?
  end
  entries << e
end

summary = {
  "generated_by" => "tools/gen_manifest.rb",
  "totals" => {
    "rules" => entries.size,
    "semgrep" => entries.count { |e| e["engine"] == "semgrep" },
    "codeql" => entries.count { |e| e["engine"] == "codeql" },
    "by_category" => entries.group_by { |e| e["category"] }.transform_values(&:size),
    "with_tests" => entries.count { |e| e["has_test"] }
  },
  "rules" => entries
}

if check_only
  puts JSON.pretty_generate(summary["totals"])
  unless problems.empty?
    warn "\nPROBLEMS (#{problems.size}):"
    problems.first(50).each { |p| warn "  - #{p}" }
    exit 1
  end
  puts "manifest check OK"
else
  File.write(File.join(ROOT, "manifest.json"), JSON.pretty_generate(summary) + "\n")
  puts "wrote manifest.json — #{entries.size} rules (#{summary["totals"]["semgrep"]} semgrep / #{summary["totals"]["codeql"]} codeql)"
end
