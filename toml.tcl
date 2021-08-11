set raw ""
set history ""

set first_clear {^(\s*(\#[^\n]*)*)*}
set clear {^(([[:blank:]]*(\#[^\n]*)*(\n|$)[[:blank:]]*)+|$)}
set key {^([A-Za-z0-9_-]+)}
set equal {^[[:blank:]]*(=)[[:blank:]]*}
set str {^(\"([^\n\"]|\\\")*\")}
set str_multiline {^(\"\"\".*?\"{3})}
set boolean {^(true|false)}
set bin {^(0b([0-1]+\_?)*[0-1])}
set oct {^(0o([0-7]+\_?)*[0-7])}
set hex {^(0x([0-9a-fA-F]+\_?)*[0-9a-fA-F])}
set dec {^((\+|\-)?(0|[1-9](\_?[0-9]+)*))}
set float {^((\+|\-)?((0|[1-9](\_?[0-9]+)*)((\.[0-9](\_?[0-9]+)*)|(\.[0-9](\_?[0-9]+)*)?(e|E)(\+|\-)?[0-9](\_?[0-9]+)*)|inf|nan))}

proc pop {t} {
  set exp [set ::$t]
  set g ""
  if {[regexp $exp $::raw r g]} {
    set ::raw [string range $::raw [string length $r] end]
    append ::history $r
  }
  return $g
}

proc err {status reason} {
  regexp {^[^\n]*} $::raw r
  throw $status "$reason: $::history$r"
}

proc find_value {} {
  foreach t {str_multiline str boolean bin oct hex float dec} {
    if {[set value [pop $t]] ne ""} {
      puts "$t:$value"
      return $value
    }
  }
  return ""
}

proc decode {raw} {
  set ::raw $raw

  pop first_clear
  set ::history ""

  while {$::raw ne ""} {
    if {[set key [pop key]] eq ""} {
      err DECODE_ERROR "Undefined key"}
    puts "Key: $key"
    if {[set equal [pop equal]] eq ""} {
      err DECODE_ERROR "Undefined = or bad key"}

    if {[set value [find_value]] eq ""} {
      err DECODE_ERROR "Undefined value"}
    puts "Value: $value"
    if {[set clear [pop clear]] eq "" && $::raw ne ""} {
      err DECODE_ERROR "Undefined newline"}
    set ::history ""
  }
}
