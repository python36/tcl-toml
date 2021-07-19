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
  if {[catch {decode $t}]} {
    puts "[puts_ok] ERROR: $t"
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
  another = "# This is not a comment"}
check_error {key = # INVALID}
check_error {first = "Tom" last = "Preston-Werner" # INVALID}
check_ok {\
  key = "value"
  bare_key = "value"
  bare-key = "value"
  1234 = "value"}
check_ok {\
  b = "ab\bc"
  t = "ab\tc"
  n = "ab\nc"
  f = "ab\fc"
  r = "ab\rc"
  quote = "ab\"c"
  backslash = "ab\\c"
  #u16 = "\u0041"
  #u32 = "\u00000041"}
check_ok {m = """hello
 wor\ 

 ld"""}
check_error {m = """hello
 wor\ ld"""}
check_ok {
  "$456" = "d"
  "$%^ 1234 kjhsd" = "d"
  "#c\fa" = "b"}
check_error {"jsh
  kjjas" = "n"}

# if {[catch {[decode {key = # INVALID}]}]} {puts "\e[1;31m ERROR parses: OK \e[0m"}
# # set d 
# # set d [decode {first = "Tom" last = "Preston-Werner" # INVALID}]
