> **Upstream Semgrep documentation snapshot — NOT an OpenGrep compatibility promise.** Retrieved and locally modified 2026-10-03 (offline links, presentation wrappers, resolved playground examples). Semgrep and upstream contributors; LGPL-2.1, provided without warranty. [License](../../LICENSE); [offline index](../../INDEX.md). Source: https://docs.semgrep.dev/writing-rules/experiments/deprecated-experiments.md

> ## Documentation Index
> Local adaptation: read the [downloaded documentation index](../../discovery/llms.txt) rather than fetching https://docs.semgrep.dev/llms.txt.
> Use this file to discover all available pages before exploring further.

# Deprecated experiments

## Equivalences



  **NOTE**

  This feature was deprecated in Semgrep v0.61.0.



Equivalences enable defining equivalent code patterns (i.e. a commutative property: `$X + $Y <==> $Y + $X`). Equivalence rules use the `equivalences` top-level key and one `equivalence` key for each equivalence.

For example:



  
[Offline playground rule and complete test cases](../../playground/jNnn.md). Original interactive execution: [https://semgrep.dev/embed/editor?snippet=jNnn](https://semgrep.dev/embed/editor?snippet=jNnn) (external).




## Extract mode



  **DEPRECATION NOTICE**

  As of Semgrep 1.65.0, extract mode has been deprecated and removed from Semgrep. This feature may return in the future.



Extract mode enables you to run existing rules on subsections of files where the rule language is different than the language of the file. For example, running a JavaScript rule on code contained inside of script tags in an HTML document.

### Example of extract mode

Without extract mode, writing rules to validate template, Markdown or configuration files which contain code in another language can be burdensome and require significant rule duplication.

Let's take the following Bash rule as an example (a simplified version of the [`curl-eval`](https://github.com/semgrep/semgrep-rules/blob/release/bash/curl/security/curl-eval.yaml) rule from the Semgrep Registry):

```yaml
rules:
  - id: curl-eval
    severity: MEDIUM
    languages:
      - bash
    message: Evaluating data from a `curl` command is unsafe.
    mode: taint
    pattern-sources:
      - pattern: |
          $(curl ...)
      - pattern: |
          `curl ...`
    pattern-sinks:
      - pattern: eval ...
```

Usually, Semgrep uses this rule only against Bash files. However, a project might contain Dockerfiles or Python scripts that invoke Bash commands—without an extract mode rule, Semgrep does **not** run any Bash rules against commands contained in files of different languages.

However, with extract mode, you can provide Semgrep with instructions on how to extract any Bash commands used in a Docker `RUN` instruction or as an argument to Python's `os.system` standard library function.

```yaml
rules:
  - id: extract-docker-run-to-bash
    mode: extract
    languages:
      - dockerfile
    pattern: RUN $...CMD
    extract: $...CMD
    dest-language: bash
  - id: extract-python-os-system-to-bash
    mode: extract
    languages:
      - python
    pattern: os.system("$CMD")
    extract: $CMD
    dest-language: bash
```

By adding the extract mode rules as shown in the previous code snippet, Semgrep matches Bash code contained in the following Python file and reports the contained Bash as matching against the `curl-eval` rule.

```python
from os import system

if system('eval `curl -s "http://www.very-secure-website.net"`'):
    print("Command failed!")
else:
    print("Success")
```

Likewise, if a query included a Dockerfile with an equivalent Bash command, Semgrep reports the contained Bash as matching against the `curl-eval` rule. See the following Dockerfile example that contains a Bash command:

```dockerfile
FROM fedora
RUN dnf install -y unzip zip curl which
RUN eval `curl -s "http://www.very-secure-website.net"`
```

### Extract mode rule schema

Extract mode rules **require** the following [usual Semgrep rule keys](../rule-syntax.md#required):

* `id`
* `languages`
* One of `pattern`, `patterns`, `pattern-either`, or `pattern-regex`

Extract mode rules **also require** two additional fields:

* `extract`
* `dest-language`

Extract mode has two **optional** fields:

* `reduce`
* `json`

The fields specific to extract mode are further explained in the sections below.

#### `extract`

The `extract` key is required in extract mode. The value must be a metavariable appearing in your pattern(s). Semgrep uses the code bound to the metavariable for subsequent queries of non-extract mode rules targeting `dest-language`.

#### `dest-language`

The `dest-language` key is required in extract mode. The value must be a [language tag](../rule-syntax.md#language-extensions-and-languages-key-values).

#### `transform`

The `transform` is an optional key in the extract mode. The value of this key specifies whether the extracted content is parsed as raw source code or as a JSON array.

The value of `transform` key must be one of the following:

`no_transform`<br />
Extract the matched content as raw source code. This is the default value.

`concat_json_string_array`<br />
Extract the matched content as a JSON array. Each element of the array corresponds to a line in the resulting source code. This value is useful in extracting code from JSON formats such as Jupyter Notebooks.

#### `reduce`

The `reduce` key is optional in extract mode. The value of this key specifies a method to combine the ranges extracted by a single rule within a file.

The value of `reduce` key must be one of the following:

`separate`<br />

Treat all matched ranges as separate units for subsequent queries. This is the **default** value.

`concat`<br />
Concatenate all matched ranges together and treat this result as a single unit for subsequent queries.

### Limitations of extract mode

Although extract mode supports JSON array decoding with the `json` key, it does not support other additional processing for the extracted text, such as unescaping strings.

While extract mode can help to enable rules which try and track taint across a language boundary within a file, taint rules cannot have a source and sink split across the original file and extracted text.

## Turbo Mode



  **NOTE**

  As of June 16th, 2025, Turbo Mode has been deprecated and removed from the Semgrep Playground.



Turbo Mode was a feature in Semgrep Editor that automatically ran your rule against Semgrep Community Edition (CE) after every keystroke or change to the rule.
