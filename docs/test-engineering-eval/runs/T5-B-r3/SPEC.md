# slugify
`slugify(text, max_length=50)` returns a lowercase ASCII slug. Accents are stripped (e-acute becomes e). Each run of non-alphanumeric characters becomes one hyphen, with no leading or trailing hyphen. The result is truncated to max_length without leaving a trailing hyphen.
