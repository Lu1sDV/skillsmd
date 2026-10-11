# Public macros

Load this only for macro-facing API work, not ordinary Rust code.

Keep input recognizable as the Rust items or expressions it produces. Preserve
applicable caller attributes, including item-level `cfg` and derives; accept
visibility modifiers rather than forcing everything public or private. Item macros
should work in the item positions they promise, including nested modules and
function-local items when appropriate. Accept complete type syntax, not just
identifier-shaped type names.

Treat generated items as public API: apply the same naming, ownership, error,
documentation, and compatibility checks as handwritten items. Do not recommend a
macro when a function, trait, or ordinary generic provides the needed behavior.

Review with a separate consumer: valid and invalid inputs, restricted visibility,
attributes, nested invocation sites, and types containing paths or generics.
Check diagnostics and generated behavior, not only successful expansion. Keep any
required imports or dependency names explicit in the invocation contract.

Basis: API Guidelines [macros](https://rust-lang.github.io/api-guidelines/macros.html)
(C-EVOCATIVE, C-MACRO-ATTR, C-ANYWHERE, C-MACRO-VIS, C-MACRO-TY).
