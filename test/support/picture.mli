(** Building levels from pictures, for tests and experiments only. This is
    NOT the real level file format (that is the level loader's job); it lets
    a test show its level as a few lines of text.

    Symbols: ['.'] floor, ['#'] wall, ['E'] exit, ['@'] start (a floor
    square), ['a'] ['b'] ['c'] keys 1-3, ['A'] ['B'] ['C'] doors 1-3,
    ['x'] ['y'] ['z'] switches 1-3, ['X'] ['Y'] ['Z'] gates 1-3. These extend
    the symbols in [test/test_rules.ml]. *)

val level : string list -> Escape.Rules.level
(** [level lines] is the level drawn by [lines], one string per row.
    Raises [Failure] on an unknown symbol, and [Rules.Invalid_level] if the
    picture is not a valid level (for example, no ['@'] or no exit). *)
