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
  }
}

proc check_ok {t} {
  if {[catch {decode $t} r]} {
    puts "[puts_error] VALID: $t\nReason: $r"
  } else {
    puts "[puts_ok] VALID: $t"
  }
}

check_ok {\
  # This is a full-line comment
  key = "value"  # This is a comment at the end of a line
  another = "# This is not a comment"
  s = "hello\"world"}
check_error {key = # INVALID}
check_error {first = "Tom" last = "Preston-Werner" # INVALID}
check_ok {empty = ""}
check_ok {\
  key ="value"
  bare_key= "value"
  bare-key="value"
  1234 = "value"}
check_error {k$y = "value"}
# check_ok {\
#   b = "ab\bc"
#   t = "ab\tc"
#   n = "ab\nc"
#   f = "ab\fc"
#   r = "ab\rc"
#   quote = "ab\"c"
#   backslash = "ab\\c"
#   u16 = "\u0041"
#   u32 = "\u00000041"}
check_ok {m = """hel"lo
 wor""

 ld"""
m2 = """111"""}
# # check_error {m = """hello
#  wor\ ld"""}
check_ok {
  "$456" = "d"
  "$%^ 1234 kjhsd" = "d"
  "#c\fa" = "b"
  "b\u0041c" = "bac"}
check_ok {
  '#c\fa' = "b"
  'b\u0041c' = "bac"}
check_error {"jsh
  kjjas" = "n"}
# check_error {ue = "\u00 41"}
check_ok {
  t = true
  f = false}
check_error {t = tr}
check_error {f = false0}
check_ok {b = 0b11
  bb = 0b111_000
  bbb = 0b111_00_1_0
  o = 0o17
  oo = 0o177_012
  h = 0x0123
  hh = 0x0012_34_56}
check_error {u = 0u99}
check_error {b = 0b12}
check_error {bb = 0b_111_000}
check_error {o = 0o18}
check_error {oo = 0_o177_012}
check_error {h = +0x0123}
check_error {hh = -0x12_34_56}
check_error {e = 0x}
check_ok {z = 0
  o = 1
  p = +3_8
  n = -18}
check_error {zz = 00}
check_error {u = +3_}
check_error {u = -_0}
check_error {u = 0_1}
check_ok {
  # fractional
  flt1 = +1.0
  flt2 = 3.1415
  flt3 = -0.01
  # exponent
  flt4 = 5e+22
  flt5 = 1e06
  flt6 = -2E-2
  # both
  flt7 = 6.626e-34
  flt_8 = 6_6.3_6
  flt_9 = 6_6.3_6e1_2}
check_error {fzz = 00.4}
check_error {invalid_float_1 = .7}
check_error {invalid_float_2 = 7.}
check_error {invalid_float_3 = 3.e+20}
check_error {invalid_float_3 = 3e+2__0}
check_error {invalid_float_3 = 3e+_2_0}
check_error {invalid_float_3 = 3e_2_0}
check_ok {
  # infinity
  sf1 = inf  # positive infinity
  sf2 = +inf # positive infinity
  sf3 = -inf # negative infinity

  # not a number
  sf4 = nan  # actual sNaN/qNaN encoding is implementation-specific
  sf5 = +nan # same as `nan`
  sf6 = -nan # valid, actual encoding is implementation-specific}
check_ok {str71 = """"This," she said, "is just a pointless statement.""" #d"""}
check_ok {str72 = """"This," she said, "is just a pointless statement."""#d"""}
check_ok {str73 = """"This," she said, "is just a pointless statement."""}
check_ok {str7 = """"This," she said, "is just a pointless statement.\"""""
  #d"""}
check_ok {str74 = """"This," she said, "is just a pointless statement.\""""""}
check_error {str75 = """"This," she said, "is just a pointless statement.""""""}
check_ok {
  str8 = """"""
  str9 = """"""""""}
check_error {str91 = """""""""""}
check_ok {
  k1 = 7
  [t1]
  k1 = 8
  [ a . b ]
  k2 = 9
}
check_error {[tr
  ]}
check_error {a.b = 3
  a. b = 5}
check_ok {a.b = 3
  a. c = 5
  a .d = 6
  a . e = 6}
check_error {a..b = 3}
check_error {a. = 3}
check_error {.a = 3}
check_ok {a."*b".7 = 3}
check_error {a.b = 3
  [a]
  c = 4}
check_error {
  [a]
  b = 3
  [a]
  c = 4}
check_ok {
  [a.b]
  b = 3
  [a.r]
  c = 4}
check_error {
  [a.b]
  b = 3
  [a]
  b = 4}
check_ok {
  [a."b.c".d]
  b = 3
  [a."b.c.d"]
  b = 4}
check_error {
  [a".b"]
  b = 3}
check_error {
  [a."b]
  b = 3}
check_error {
  [a.b"]
  b = 3}

check_ok {
  [ a . b . c ]
  b.v = 3}
check_error {
  a.b = 3
  a.b.c = 4
}
check_ok {
  a.b.c.g.h = 3
  a.b.f = 4
}
check_ok {
  [[   at   ]]
  a = 1
  [[at]]
  a = 2
}
check_error {[[      ]]}
check_error {[   ]}
check_error {[]}
check_error {[[]]}
check_ok {
  [[a.b.c]]
  a = 1
  [[at]]
  a = 2
}
check_ok {
  [[a.b.c]]
  a = 1
  b = 3
  [[a.b.c]]
  a = 2
}
check_ok {
  [[a.b]]
  a = 1
  cc = 3
  [[a.b.c]]
  a = 2
}
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

check_ok {[[products]]
name = "Hammer"
sku = 738594937

[[products]]  # empty table within the array

[[products]]
name = "Nail"
sku = 284758393

color = "gray"}

check_error {[fruit.physical]  # subtable, but to which parent element should it belong?
color = "red"
shape = "round"

[[fruit]]  # parser must throw an error upon discovering that "fruit" is
           # an array rather than a table
name = "apple"}

check_error {[[fruits]]
name = "apple"

[[fruits.varieties]]
name = "red delicious"

# INVALID: This table conflicts with the previous array of tables
[fruits.varieties]
name = "granny smith"}

check_error {[[fruits]]
name = "apple"

[fruits.physical]
color = "red"
shape = "round"

# INVALID: This array of tables conflicts with the previous table
[[fruits.physical]]
color = "green"}

check_ok {
  integers = [ 1, 2, 3 ]
  colors = [ "red", "yellow", "green" ]
  nested_arrays_of_ints = [ [ 1, 2 ], [3, 4, 5] ]
  nested_mixed_array = [ [ 1, 2 ], ["a", "b", "c"] ]
}

check_ok {
  integers2 = [
    1, 2, 3
  ]

  integers3 = [
    1,
    2, # this is ok
  ]

  integers4 = [
  # first comment

  7,

  [5,#second comment
    6]
  ,3]
  array_empty = []
}
check_error {
  integers2 = [
    1, 2, 3,,
  ]
}
check_ok {
  ld1 = 1979-05-27
  lt1 = 07:32:00
  lt2 = 00:32:00.999999
}
check_error {
  ld1 = 1979-5-27
}
check_error {
  ld1 = 1979-05-61
}
check_error {
  ld1 = 1979-14-06
}
check_error {
  ld1 = 13:59:90
}
check_ok {
  ldt1 = 1979-05-27T07:32:00
  ldt2 = 1979-05-27T00:32:00.999999
  ldt11 = 1979-05-27 07:32:00
  ldt22 = 1979-05-27 00:32:00.999999
}
check_ok {
  odt1 = 1979-05-27T07:32:00Z
  odt2 = 1979-05-27T00:32:00-07:00
  odt3 = 1979-05-27T00:32:00.999999-07:00
  odt4 = 1979-05-27 07:32:00Z
}
check_error {
  odt1 = 1979-05-27T07:32:00-24:00
}
check_ok {name = { first = "Tom", last = "Preston-Werner" }
  point = { x = 1, y = 2 }
  animal = { type.name = "pug" }}
check_error {name = { first = "Tom", last = "Preston-Werner" }
  name.a = 9}
