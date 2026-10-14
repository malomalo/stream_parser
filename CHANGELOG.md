## head

* Track positions as byte offsets internally so scanning no longer slows
  down quadratically with the length of the source. Requires Ruby 3.4 or
  newer for `MatchData#byteend`. Subclasses that read `@index` or
  `@old_index` directly now get byte offsets; `forward`, `rewind`, `seek`,
  `peek`, `next_char` and `prev_char` still count characters.
* `rewind` steps back over UTF-8 continuation bytes instead of copying and
  counting the source before the current position, so it no longer costs
  the length of the source in non-ASCII text.

## v0.5

* Adding `frozen_string_literal` in preperation for Ruby 3.5 and silence Ruby 3.4
  warnings

## v0.4

* `quoted_value` now raises a `StreamParser::SyntaxError` when encountering value
  that is not fully quoted.
