proc create_pair {} {
  puts ">>$::key = $::value<<"
  set ::key ""
  set ::value ""

  return wait_newline
}

# TODO
# single quotes
# utf-32
# integer
# float
# boolean

source unicode.tcl

proc is_whitespace {c}  {
  return [expr {"$c"} == {" "} || {"$c"} == {"\t"}]
}

proc is_digit {c} {
  return [regexp {^\d$} $c]
}

proc is_alpha {c} {
  return [regexp {^[a-zA-Z]$} $c]
}

proc is_alphanum {c} {
  return [regexp {^[a-zA-Z0-9]$} $c]
}

proc is_barekey {c} {
  return [regexp {^[a-zA-Z0-9_-]$} $c]
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
  } elseif {$c == {#}} {
    return comment_parser
  } elseif {$c == {"}} {
    return [quoted_key_parser $c]
  } elseif {[is_barekey $c]} {
    return [bare_key_parser $c]
  }
  throw DECODE_ERROR "Bad key start symbol :$c"
}

proc quoted_key_parser {c} {
  if {$c == {"}} {
    if {$::key ne ""} {
      set ::key [string range $::key 1 end]
      return key_parser_wait_eq
    }
  } elseif {$c == "\\"} {
    return escaped_symbol_in_key_parser
  } elseif {$c == "\n"} {
    throw DECODE_ERROR "The key cannot be multi-line "
  }
  append ::key $c
  return quoted_key_parser
}

proc escaped_symbol_in_key_parser {c} {
  if {$c == "\n" || [is_whitespace $c]} {
    throw DECODE_ERROR "Expected \"=\" or whitespace after key, but passed $c"
  }
}

proc escaped_symbol_in_key_parser {c} {
  if {$c in {b t n f r \" \\}} {
    set ::key "${::key}[join "\\$c" ""]"
    return quoted_key_parser
  } elseif {$c == "u"} {
    return unicode_key_parser
  }
  throw DECODE_ERROR "Bad escape sequence: \\$c"
}

proc unicode_key_parser {c} {
  if {[Unicode::update $c]} {
    append ::key $Unicode::value
    return quoted_key_parser
  }
  return unicode_key_parser
}

proc bare_key_parser {c} {
  if {[is_barekey $c]} {
    append ::key $c
  } else {
    return [key_parser_wait_eq $c]
  }
  return bare_key_parser
}

proc key_parser_wait_eq {c} {
  if {$c == {=}} {
    return value_parser_wait_start
  } elseif {![is_whitespace $c]} {
    throw DECODE_ERROR "Expected \"=\" or whitespace after key, but passed $c"
  }
  return key_parser_wait_eq
}

proc value_string_parser {c} {
  if {$c == "\\"} {
    return escaped_symbol_in_value_parser
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
  return value_string_parser
}

proc escaped_symbol_in_value_parser {c} {
  if {$c == "\n" || [is_whitespace $c]} {
    if {[string range $::value 0 2] ne {"""}} {
      throw DECODE_ERROR "Line ending backslash allowed only in multistring value"
    }
    return line_ending_backslash_parser
  }
  return [escaped_symbol_in_value_parser_now_whitespace $c]
}

proc line_ending_backslash_parser {c} {
  if {[is_whitespace $c]} {
    return line_ending_backslash_parser
  } elseif {$c == "\n"} {
    return line_ending_backslash_parser_2_step
  }
  throw DECODE_ERROR "After \"\\ \" must be only whitespace or newline"
}

proc line_ending_backslash_parser_2_step {c} {
  if {$c == "\n" || [is_whitespace $c]} {
    return line_ending_backslash_parser_2_step
  }
  return [value_string_parser $c]
}

proc escaped_symbol_in_value_parser_now_whitespace {c} {
  if {$c in {b t n f r \" \\}} {
    set ::value "${::value}[join "\\$c" ""]"
    return value_string_parser
  } elseif {$c == "u"} {
    return unicode_parser
  }
  throw DECODE_ERROR "Bad escape sequence: \\$c"
}

proc unicode_parser {c} {
  if {[Unicode::update $c]} {
    append ::value $Unicode::value
    return value_string_parser
  }
  return unicode_parser
}

proc value_parser_wait_start {c} {
  if {[is_whitespace $c] || $c == "\n"} {
    return value_parser_wait_start
  }
  return [value_parser_ident $c]
}

proc value_parser_ident {c} {
  if {$c == {+} || $c == {-} || [is_digit $c]} {
    return [number_parser $c]
  } elseif {$c == {t} || $c == {f}} {
    return [boolean_parser $c]
  } elseif {$c == "\""} {
    return [value_string_parser $c]
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
  set ::key ""
  set ::value ""

  set parser first_parser
  foreach c [split $raw ""] {
    set parser [$parser $c]
    # puts "$parser $c"
  }
  if {$::key ne "" || $::value ne ""} {
    throw DECODE_ERROR "Not finished record"
  }
}
