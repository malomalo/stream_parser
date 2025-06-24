## head

## v0.5

* Adding `frozen_string_literal` in preperation for Ruby 3.5 and silence Ruby 3.4
  warnings

## v0.4

* `quoted_value` now raises a `StreamParser::SyntaxError` when encountering value
  that is not fully quoted.
