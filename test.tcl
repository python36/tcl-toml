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
# check_error {"jsh
#   kjjas" = "n"}
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
check_ok {a.b = 3
  a. b = 5
  a .b = 6
  a . b = 6}
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

