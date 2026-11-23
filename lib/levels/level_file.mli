(** Reading and writing handwritten level files. The format is documented in
    [docs/level_format.md]. A short example:

    {v
; MS2 demo level
name: demo
keys: red
doors: red
map:
#########
#@..k#..#
#....D.E#
#########
    v} *)

(** Why a file could not be turned into a level. *)
type error =
  | Cannot_read of string  (** the file could not be opened or read *)
  | Syntax of {
      line : int;  (** 1-based line number in the file *)
      message : string;
    }  (** the text does not follow the format *)
  | Invalid_level of string
      (** the text follows the format, but the layout breaks a rule in
          {!Level.make}, such as a missing exit *)

val error_to_string : error -> string
(** A one-line message suitable for showing to the player, such as
    ["line 7: unknown symbol 'x' in column 3"]. *)

val parse : ?default_name:string -> string -> (Level.t, error) result
(** [parse text] reads a level from the contents of a level file. If the file
    has no [name:] line, the level is named [default_name] (default
    ["unnamed"]). Never returns [Cannot_read]. *)

val load : string -> (Level.t, error) result
(** [load path] reads and parses the file at [path]. A file without a [name:]
    line is named after the file: ["levels/demo.txt"] becomes ["demo"]. *)

val to_string : Level.t -> string
(** [to_string lvl] writes [lvl] in the level file format, so that
    [parse (to_string lvl)] gives back a level equal to [lvl]. *)
