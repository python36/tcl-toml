source toml.tcl

set bad 0
set valid 0

proc puts_ok {} {
  incr ::valid
  return "\[\033\[1;32mOK\033\[0m\]"
}

proc puts_error {} {
  incr ::bad
  return "\[\033\[1;31mERROR\033\[0m\]"
}

proc check_error {t} {
  if {[catch {decode $t} e]} {
    puts "[puts_ok] ERROR $e"
  } else {
    puts "[puts_error] ERROR: $t"
    exit 1
  }
}

proc check_ok {t} {
  if {[catch {set res [decode $t]} r]} {
    puts "[puts_error] VALID: $t\nReason: $r"
    exit 1
  } else {
    puts "[puts_ok] VALID: $t\n---\n[huddle jsondump $res]"
  }
}

check_ok {
  # This is a full-line comment
  key = "value"  # This is a comment at the end of a line
  another = "# This is not a comment"}
check_ok {key = "value"}
check_error {key = # INVALID}
check_error {first = "Tom" last = "Preston-Werner" # INVALID}
check_ok {key = "value"
  bare_key = "value"
  bare-key = "value"
  1234 = "value"}
check_ok {"127.0.0.1" = "value"
  "character encoding" = "value"
  "ʎǝʞ" = "value"
  'key2' = "value"
  'quoted "value"' = "value"}
check_error {= "no key name"  # INVALID}
check_ok {"" = "blank"     # VALID but discouraged}
check_ok {'' = 'blank'     # VALID but discouraged}
check_ok {name = "Orange"
  physical.color = "orange"
  physical.shape = "round"
  site."google.com" = true}
check_ok {fruit.name = "banana"     # this is best practice
  fruit. color = "yellow"    # same as fruit.color
  fruit . flavor = "banana"   # same as fruit.flavor}
check_error {# DO NOT DO THIS
  name = "Tom"
  name = "Pradyun"}
check_error {# THIS WILL NOT WORK
  spelling = "favorite"
  "spelling" = "favourite"}
check_ok {# This makes the key "fruit" into a table.
  fruit.apple.smooth = true

  # So then you can add to the table "fruit" like so:
  fruit.orange = 2}
check_error {# THE FOLLOWING IS INVALID

  # This defines the value of fruit.apple to be an integer.
  fruit.apple = 1

  # But then this treats fruit.apple like it's a table.
  # You can't turn an integer into a table.
  fruit.apple.smooth = true}
check_ok {# VALID BUT DISCOURAGED

  apple.type = "fruit"
  orange.type = "fruit"

  apple.skin = "thin"
  orange.skin = "thick"

  apple.color = "red"
  orange.color = "orange"}
check_ok {# RECOMMENDED

  apple.type = "fruit"
  apple.skin = "thin"
  apple.color = "red"

  orange.type = "fruit"
  orange.skin = "thick"
  orange.color = "orange"}
check_ok {3.14159 = "pi"}
check_ok {str = "I'm a string. \"You can quote me\". Name\tJos\u00E9\nLocation\tSF."}
check_ok {str1 = """
Roses are red
Violets are blue"""}
check_ok {# On a Unix system, the above multi-line string will most likely be the same as:
  str2 = "Roses are red\nViolets are blue"

  # On a Windows system, it will most likely be equivalent to:
  str3 = "Roses are red\r\nViolets are blue"}
check_ok {# The following strings are byte-for-byte equivalent:
str1 = "The quick brown fox jumps over the lazy dog."

str2 = """
The quick brown \ 


  fox jumps over \ 
    the lazy dog."""

str3 = """\ 
       The quick brown \ 
       fox jumps over \ 
       the lazy dog.\ 
       """}
check_ok {str4 = """Here are two quotation marks: "". Simple enough."""
  # str5 = """Here are three quotation marks: """."""  # INVALID
  str5 = """Here are three quotation marks: ""\"."""
  str6 = """Here are fifteen quotation marks: ""\"""\"""\"""\"""\"."""

  # "This," she said, "is just a pointless statement."
  str7 = """"This," she said, "is just a pointless statement.""""}
check_ok {# What you see is what you get.
  winpath  = 'C:\Users\nodejs\templates'
  winpath2 = '\\ServerX\admin$\system32\'
  quoted   = 'Tom "Dubs" Preston-Werner'
  regex    = '<\i\c*\s*>'}
check_ok {regex2 = '''I [dw]on't need \d{2} apples'''
lines  = '''
The first newline is
trimmed in raw strings.
   All other whitespace
   is preserved.
'''}
check_ok {quot15 = '''Here are fifteen quotation marks: """""""""""""""'''

  # apos15 = '''Here are fifteen apostrophes: ''''''''''''''''''  # INVALID
  apos15 = "Here are fifteen apostrophes: '''''''''''''''"

  # 'That,' she said, 'is still pointless.'
  str = ''''That,' she said, 'is still pointless.''''}
check_ok {int1 = +99
  int2 = 42
  int3 = 0
  int4 = -17}
check_ok {int5 = 1_000
  int6 = 5_349_221
  int7 = 53_49_221  # Indian number system grouping
  int8 = 1_2_3_4_5  # VALID but discouraged}
check_ok {# hexadecimal with prefix `0x`
  hex1 = 0xDEADBEEF
  hex2 = 0xdeadbeef
  hex3 = 0xdead_beef

  # octal with prefix `0o`
  oct1 = 0o01234567
  oct2 = 0o755 # useful for Unix file permissions

  # binary with prefix `0b`
  bin1 = 0b11010110}
check_ok {# fractional
  flt1 = +1.0
  flt2 = 3.1415
  flt3 = -0.01

  # exponent
  flt4 = 5e+22
  flt5 = 1e06
  flt6 = -2E-2

  # both
  flt7 = 6.626e-34}
check_error {invalid_float_1 = .7}
check_error {invalid_float_2 = 7.}
check_error {invalid_float_2 = 7.}
check_ok {flt8 = 224_617.445_991_228}
puts [decode {# infinity
  sf1 = inf  # positive infinity
  sf2 = +inf # positive infinity
  sf3 = -inf # negative infinity}]
puts [decode {
  # not a number
  sf4 = nan  # actual sNaN/qNaN encoding is implementation-specific
  sf5 = +nan # same as `nan`
  sf6 = -nan # valid, actual encoding is implementation-specific}]
check_ok {bool1 = true
  bool2 = false}
check_ok {odt1 = 1979-05-27T07:32:00Z
  odt2 = 1979-05-27T00:32:00-07:00
  odt3 = 1979-05-27T00:32:00.999999-07:00}
check_ok {odt4 = 1979-05-27 07:32:00Z}
check_ok {ldt1 = 1979-05-27T07:32:00
  ldt2 = 1979-05-27T00:32:00.999999}
check_ok {ld1 = 1979-05-27}
check_ok {lt1 = 07:32:00
  lt2 = 00:32:00.999999}
check_ok {integers = [ 1, 2, 3 ]
  colors = [ "red", "yellow", "green" ]
  nested_arrays_of_ints = [ [ 1, 2 ], [3, 4, 5] ]
  nested_mixed_array = [ [ 1, 2 ], ["a", "b", "c"] ]
  string_array = [ "all", 'strings', """are the same""", '''type''' ]

  # Mixed-type arrays are allowed
  numbers = [ 0.1, 0.2, 0.5, 1, 2, 5 ]
  contributors = [
    "Foo Bar <foo@example.com>",
    { name = "Baz Qux", email = "bazqux@example.com", url = "https://example.com/bazqux" }
  ]}
check_ok {integers2 = [
    1, 2, 3
  ]

  integers3 = [
    1,
    2, # this is ok
  ]}
check_ok {[table]}
check_ok {[table-1]
  key1 = "some string"
  key2 = 123

  [table-2]
  key1 = "another string"
  key2 = 456}
check_ok {[dog."tater.man"]
  type.name = "pug"}
check_ok {[a.b.c]            # this is best practice
  [ d.e.f ]          # same as [d.e.f]
  [ g .  h  . i ]    # same as [g.h.i]
  [ j . "ʞ" . 'l' ]  # same as [j."ʞ".'l']}
check_ok {# [x] you
  # [x.y] don't
  # [x.y.z] need these
  [x.y.z.w] # for this to work

  [x] # defining a super-table afterward is ok}
check_error {# DO NOT DO THIS

  [fruit]
  apple = "red"

  [fruit]
  orange = "orange"}
check_error {# DO NOT DO THIS EITHER

  [fruit]
  apple = "red"

  [fruit.apple]
  texture = "smooth"}
check_ok {# VALID BUT DISCOURAGED
  [fruit.apple]
  [animal]
  [fruit.orange]}
check_ok {# RECOMMENDED
  [fruit.apple]
  [fruit.orange]
  [animal]}
check_ok {# Top-level table begins.
  name = "Fido"
  breed = "pug"

  # Top-level table ends.
  [owner]
  name = "Regina Dogman"
  member_since = 1999-08-04}
check_ok {fruit.apple.color = "red"
  # Defines a table named fruit
  # Defines a table named fruit.apple

  fruit.apple.taste.sweet = true
  # Defines a table named fruit.apple.taste
  # fruit and fruit.apple were already created}
check_error {[fruit]
  apple.color = "red"
  apple.taste.sweet = true

  [fruit.apple]  # INVALID}
check_error {[fruit]
  apple.color = "red"
  apple.taste.sweet = true

  [fruit.apple.taste]  # INVALID}
check_ok {[fruit]
  apple.color = "red"
  apple.taste.sweet = true
  [fruit.apple.texture]  # you can add sub-tables
  smooth = true}
check_ok {name = { first = "Tom", last = "Preston-Werner" }
  point = { x = 1, y = 2 }
  animal = { type.name = "pug" }}
check_ok {[name]
  first = "Tom"
  last = "Preston-Werner"

  [point]
  x = 1
  y = 2

  [animal]
  type.name = "pug"}
check_error {[product]
  type = { name = "Nail" }
  type.edible = false  # INVALID}
check_error {[product]
  type.name = "Nail"
  type = { edible = false }  # INVALID}
decode {[[products]]
  name = "Hammer"
  sku = 738594937

  [[products]]  # empty table within the array

  [[products]]
  name = "Nail"
  sku = 284758393

  color = "gray"}
check_ok {[[fruits]]
  name = "apple"

  [fruits.physical]  # subtable
  color = "red"
  shape = "round"

  [[fruits.varieties]]  # nested array of tables
  name = "red delicious"

  [[fruits.varieties]]
  name = "granny smith"


  [[fruits]]
  name = "banana"

  [[fruits.varieties]]
  name = "plantain"}
check_error {# INVALID TOML DOC
  [fruit.physical]  # subtable, but to which parent element should it belong?
  color = "red"
  shape = "round"

  [[fruit]]  # parser must throw an error upon discovering that "fruit" is
             # an array rather than a table
  name = "apple"}
check_error {# INVALID TOML DOC
  fruits = []

  [[fruits]] # Not allowed}
check_error {# INVALID TOML DOC
  [[fruits]]
  name = "apple"

  [[fruits.varieties]]
  name = "red delicious"

  # INVALID: This table conflicts with the previous array of tables
  [fruits.varieties]
  name = "granny smith"}
check_error {# INVALID TOML DOC
  [[fruits]]
  name = "apple"

  [fruits.physical]
  color = "red"
  shape = "round"

  # INVALID: This array of tables conflicts with the previous table
  [[fruits.physical]]
  color = "green"}
check_ok {
  points = [ { x = 1, y = 2, z = 3 },
             { x = 7, y = 8, z = 9 },
             { x = 2, y = 4, z = 8 } ]}

puts "\nOK! $valid successful tests"
