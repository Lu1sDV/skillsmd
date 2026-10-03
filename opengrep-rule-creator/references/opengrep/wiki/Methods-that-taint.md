# Specific collection methods have effect taints on the collection.

The need for that was found in BenchmarkJava
#### Before the fix we had:
- without taint-intrafile 3608 finds
with intrafile 3404  finds


#### After the fix
- without taint-intrafile 3608 finds
- with intrafile 3740  finds finds
#### More details:
 - 53 of the finds without taint-intrafile are actually FP. 
 
 
  | Pattern                         | Count | Sanitizer                 |
  |---------------------------------|-------|---------------------------|
  | barbarians _at_the_gate pattern                    | 34    | Static string replacement |
  | ESAPI.encoder().encodeForHTML() | 13    | In rule                   |
  | HtmlUtils.htmlEscape()          | 1     | In rule                   |
  | StringEscapeUtils.escapeHtml()  | 5     | In rule                   |
 
 
 - 185 new finds in taint-intrafile
 
 | Category           | Count | Description                                            |
  |--------------------|-------|--------------------------------------------------------|
  | HashMap pattern    | 71    | map.put(key, tainted) → map.get(key) → sink            |
  | List pattern       | 113   | list.add(tainted) → list.get(i) or ProcessBuilder args |
  | Non-literal regexp | 1     | JavaScript RegExp detection (separate rule)            |
 
 # Summary

  - Add built-in taint models for collection operations across 10 languages
  - Fix lambda interprocedural taint flow by passing signature databases to lambda analysis

  Collection Models

  Two types of models:

  ArgTaintsThis - Mutator methods where an argument taints the receiver:
  - map.put(key, value) → value taints map
  - list.add(item) → item taints list
  - sb.append(str) → str taints sb (+ returns this for fluent APIs)

  ThisTaintsReturn - Accessor methods where receiver taints return value:
  - map.get(key) → map taint flows to return
  - list.pop() → list taint flows to return
  - sb.toString() → sb taint flows to return

  | Language | Mutators                                                | Accessors                                                  |
  |----------|---------------------------------------------------------|------------------------------------------------------------|
  | Java     | put, putIfAbsent, add, set, append, insert, push, offer | get, peek, poll, pop, remove, toString, next               |
  | JS/TS    | set, push, unshift, add                                 | get, pop, shift, at, toString, valueOf, join               |
  | Python   | append, add, insert, extend, update                     | pop, get, setdefault, copy, keys, values, items            |
  | Ruby     | push, append, unshift, prepend, merge!, update          | pop, shift, first, last, fetch, dig, to_s, join            |
  | C#       | Add, Push, Enqueue, Insert, TryAdd                      | Pop, Dequeue, Peek, ElementAt, GetValueOrDefault, ToString |
  | Kotlin   | add, put, putIfAbsent, append                           | get, getOrNull, getOrDefault, first, last, toString        |
  | Swift    | append, insert, updateValue                             | popLast, removeFirst, removeLast, first, last, remove      |
  | Rust     | push, push_front, push_back, insert                     | pop, get, get_mut, remove, iter                            |
  | Scala    | append, prepend, addOne, add, put, update               | head, last, apply, get, getOrElse, mkString, toString      |
  | Go       | Store (sync.Map)                                        | Load (sync.Map)                                            |
