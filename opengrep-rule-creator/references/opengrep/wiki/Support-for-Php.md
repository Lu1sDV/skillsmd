 This document summarizes the PHP language improvements added to Opengrep in 2025.

 ## Supported features

 Here are the PHP features now supported, organized by PHP version:

 | Feature | Support | Notes |
 |--------|---------|-------|
 | **PHP 7.1** |||
 | - Union types in catch | ✅ | [Note](#multi-catch-exception-handling) |
 | - Class constant visibility | ✅ | [Note](#class-constant-visibility) |
 | **PHP 7.4** |||
 | - Arrow functions | ✅ | [Note](#arrow-functions) |
 | **PHP 8.0** |||
 | - Union types | ✅ | [Note](#union-types) |
 | - Match expressions | ✅ | [Note](#match-expressions) |
 | - Null coalesce throw | ✅ | [Note](#null-coalesce-with-throw) |
 | - Static return type | ✅ ||
 | **PHP 8.1** |||
 | - Enums | ✅ | [Note](#enums) |
 | - First-class callable syntax | ✅ | [Note](#first-class-callable-syntax) |
 | **PHP 8.2** |||
 | - Readonly classes | ✅ | [Note](#readonly-classes) |
 | - DNF types | ✅ | [Note](#dnf-types) |
 | **PHP 8.3** |||
 | - Dynamic constant fetch | ✅ | [Note](#dynamic-constant-fetch) |
 | **PHP 8.4** |||
 | - Property hooks | ✅ | [Note](#property-hooks) |
 | - Asymmetric visibility | ✅ | [Note](#asymmetric-visibility) |
 | **Infrastructure** |||
 | - Thread-safe lexer | ✅ | [Note](#thread-safe-lexer) |
 | - Interpolated string parsing | ✅ | [Note](#interpolated-strings) |


 ## Union types

 [PR #201](https://github.com/opengrep/opengrep/pull/201) 

 The Menhir parser was missing union types. Union types in the tree-sitter parser are translated to tuples, and the Menhir parser now follows the same approach for consistency.

 ```php
 function processInput(int|string $value): int|null {
     if (is_string($value)) {
         return strlen($value);
     }
     return $value > 0 ? $value : null;
 }
 ```

 ## Arrow functions

 [PR #205](https://github.com/opengrep/opengrep/pull/205) 

 Added PHP 7.4 arrow function syntax to the Menhir parser. PHP arrow functions (`fn($x) => $x + 1`) are syntactically different from Facebook's HHVM extension syntax (`$x ==> $x + 1`), but both are represented the same way in the AST.

 ```php
 $fn = fn($x) => $x + 1;

 // Equivalent to:
 $fn = function($x) {
     return $x + 1;
 };
 ```

 ## Interpolated strings

 [PR #296](https://github.com/opengrep/opengrep/pull/296) 

 Fixed a bug in the tree-sitter parser where interpolated strings were incorrectly parsed as literal strings. For example:

 ```php
 "convert $filename"
 ```

 was being parsed literally as a string instead of recognizing `$filename` as an interpolated variable.

 ## Null coalesce with throw

 [PR #296](https://github.com/opengrep/opengrep/pull/296) 

 The Menhir parser was missing the `??` token for PHP 8.0's null coalesce operator. Additionally, `throw` was modified to be parsed as an expression so it can be used with `??`.

 ```php
 return shell_exec($command)
     ?? throw new RuntimeException('Failed to execute command');
 ```

 ## Match expressions

 [PR #306](https://github.com/opengrep/opengrep/pull/306) 

 Added PHP 8.0 match expressions to the Menhir parser. Also fixed an issue in switch (and match) that prevented ellipses in the body. The following patterns are now valid:

 ```php
 switch($F) {
     ...
 }

 match ($F) {
     ...
 }
 ```

 ## Enums

 [PR #306](https://github.com/opengrep/opengrep/pull/306) 

 Added PHP 8.1 enum definitions including backed enums:

 ```php
 enum Status: string {
     case Active = 'active';
     case Pending = 'pending';
     case Inactive = 'inactive';
 }
 ```

 ## Multi-catch exception handling

 [PR #529](https://github.com/opengrep/opengrep/pull/529) 

 PHP 7.1 multi-catch syntax allowing multiple exception types in a single catch block:

 ```php
 try {
     riskyOperation();
 } catch (InvalidArgumentException | TypeError | ValueError $e) {
     handleError($e);
 }
 ```

 ## Class constant visibility

 [PR #529](https://github.com/opengrep/opengrep/pull/529) 

 PHP 7.1 visibility modifiers for class constants:

 ```php
 class Config {
     public const PUBLIC_CONST = 1;
     protected const PROTECTED_CONST = 2;
     private const PRIVATE_CONST = 3;
 }
 ```

 ## First-class callable syntax

 [PR #529](https://github.com/opengrep/opengrep/pull/529) 

 PHP 8.1 first-class callable syntax creates closures from callables:

 ```php
 $fn = strlen(...);           // Closure::fromCallable('strlen')
 $fn = $obj->method(...);     // Closure::fromCallable([$obj, 'method'])
 $fn = Foo::bar(...);         // Closure::fromCallable([Foo::class, 'bar'])
 ```

 ### Note: 
In Opengrep patterns, `...` retains its ellipsis meaning for pattern matching. In particular in order to wrote a pattern that matches a "callable ..." you need to use `Closure::fromCallable`

 ## Readonly classes

 [PR #529](https://github.com/opengrep/opengrep/pull/529) 

 PHP 8.2 readonly classes where all properties are implicitly readonly:

 ```php
 readonly class ImmutablePoint {
     public int $x;
     public int $y;
 }
 ```

 ## DNF types

 [PR #529](https://github.com/opengrep/opengrep/pull/529) 

 PHP 8.2 Disjunctive Normal Form types combine union and intersection types:

 ```php
 function process((Countable&Iterator)|null $input): (A&B)|C {
     // ...
 }
 ```

 ## Dynamic constant fetch

 [PR #529](https://github.com/opengrep/opengrep/pull/529) 

 PHP 8.3 dynamic class constant fetch allows accessing constants using variable names:

 ```php
 $name = 'VERSION';
 echo Config::{$name};
 ```

 ## Property hooks

 [PR #529](https://github.com/opengrep/opengrep/pull/529) 

 PHP 8.4 property hooks allow defining custom get/set behavior directly on properties:

 ```php
 class User {
     // Block syntax
     public string $name {
         get { return $this->name; }
         set { $this->name = strtoupper($value); }
     }

     // Arrow syntax
     public int $age {
         get => $this->age;
         set => max(0, $value);
     }
 }
 ```

 ## Asymmetric visibility

 [PR #529](https://github.com/opengrep/opengrep/pull/529) 

 PHP 8.4 asymmetric visibility allows different visibility for reading and writing properties:

 ```php
 class Counter {
     public private(set) int $count = 0;      // Public read, private write
     public protected(set) string $name = ""; // Public read, protected write
 }
 ```

 ## Thread-safe lexer

 [PR #123](https://github.com/opengrep/opengrep/pull/123) 

 The PHP primary parser lexer was made thread-safe as part of the transition from parmap to domainslib. This enables parallel file processing without race conditions and improves performance on multi-core systems.



 