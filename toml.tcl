set key ""
set value ""

proc create_pair {} {
  puts "$::key = $::value"
  set ::key ""
  set ::value ""

  return wait_newline
}

proc is_whitespace {c}  {
  return [expr {"$c"} == {" "} || {"$c"} == {"\t"}]
}

proc is_digit {c} {
  return [regexp {^\d$} $c]
}

proc bare_key_check {c} {
  return [expr ( {"$c"} >= {"A"} && {"$c"} <= {"Z"} ) ||\
               ( {"$c"} >= {"a"} && {"$c"} <= {"z"} ) ||\
               ( {"$c"} >= {"0"} && {"$c"} <= {"9"} ) ||\
               {"$c"} == {"_"} || {"$c"} == {"-"}]
}

proc wait_newline {c} {
  if {[is_whitespace $c]} {
    return wait_newline
  } elseif {$c == "\n"} {
    return first_parser
  } elseif {$c == {#}} {
    return comment_parser
  }
  throw DECODE_ERROR "There must be a newline (or EOF) after a key/value pair."
}

proc first_parser {c} {
  if {$c == "\n" || [is_whitespace $c]} {
    return first_parser
  }
  if {$c == {#}} {
    return comment_parser
  }
  if {[bare_key_check $c]} {
    return [bare_key_parser $c]
  }
  return first_parser
}

proc bare_key_parser {c} {
  if {($c >= {A} && $c <= {Z}) || ($c >= {a} && $c <= {z}) || $c == {_} || $c == {-}} {
    append ::key $c
  } else {
    return [bare_key_parser_wait_eq $c]
  }
  return bare_key_parser
}

proc bare_key_parser_wait_eq {c} {
  if {$c == {=}} {
    return value_parser_wait_start
  } elseif {![is_whitespace $c]} {
    throw DECODE_ERROR "Expected \"=\" or whitespace after key, but passed $c"
  }
  return bare_key_parser_wait_eq
}

proc string_parser {c} {
  if {$c == "\\"} {
    return escaped_symbol_parser
  } elseif {$c == "\""} {
    if {$::value ne ""} {
      if {$::value ne {"} && $::value ne {""}} {
        if {[string range $::value 0 2] eq {"""}} {
          if {[string range $::value end-1 end] eq {""}} {
            set ::value [string range $::value 3 end-2]
            return [create_pair]
          }
        } else {
          set ::value [string range $::value 1 end]
          return [create_pair]
        }
      }
    }
  }
  set ::value "${::value}$c"
  return string_parser
}

proc escaped_symbol_parser {c} {
  if {$c in "btnfr\"\\"} {
    set ::value "${::value}[join "\\$c" ""]"
  } elseif {$c == "u"} {
    return unicode_parser
  }
  throw DECODE_ERROR "Bad escape sequence: \\$c"
}

proc value_parser_wait_start {c} {
  if {[is_whitespace $c]} {
    return value_parser_wait_start
  }
  return [value_parser_ident $c]
}

proc value_parser_ident {c} {
  if {$c == {+} || $c == {-} || [is_digit $c]} {
    return [number_parser $c]
  } elseif {$c == {t} || $c == {f}} {
    return [boolean_parser $c]
  } elseif {$c == {"}} {
    return [string_parser $c]
  } elseif {$c == {[}} {
    return [array_parser $c]
  } elseif {$c == "\{"} {
    return [inline_table_parser $c]
  }
  throw DECODE_ERROR "Bad first symbol in value: $c"
}

proc comment_parser {c} {
  if {$c == "\n"} {
    return first_parser
  }
  return comment_parser
}

proc decode {raw} {
  set parser first_parser
  foreach c [split $raw ""] {
    set parser [$parser $c]
    # puts "$parser $c"
  }
}
