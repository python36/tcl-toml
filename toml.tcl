package require huddle

source huddle_ext_types.tcl

# https://wiki.tcl-lang.org/page/Time+and+date+validator
proc timevalidate {format str} {
  # Start with a simple check: If the string cannot be parsed against
  # the specified format at all it's definitely wrong
  if {[catch {clock scan $str -format $format} time]} {return 0}

  # Create a table for translating the supported clock format specifiers
  # to scan format specifications
  set map {%a %3s %A %s %b %3s %B %s %d %2d %D %2d/%2d/%4d
    %e %2d %g %2d %G %4d %h %s %H %2d %I %2d %j %3d
    %J %d %k %2d %l %2d %m %2d %M %2d %N %2d %p %2s
    %P %2s %s %d %S %2d %t \t %T %2d:%2d:%2d %u %1d
    %V %2d %w %1d %W %2d %y %2d %Y %4d %z %4d %Z %s
  }

  # Build the scan format string out of the clock format string
  set scanfmt [string map $map $format]

  # Recreate the time string from the seconds value
  set tmp [clock format $time -format $format]

  # Scan both versions of the string representation
  set list1 [scan $str $scanfmt]
  set list2 [scan $tmp $scanfmt]

  # Compare all elements as numbers and strings
  foreach n1 $list1 n2 $list2 {
    if {$n1 != $n2 && ![string equal -nocase $n1 $n2]} {return 0}
  }

  # Declare the time string valid since all elements matched
  return 1
}

proc validate_date {s} {
  if {![timevalidate %Y-%m-%d $s]} {
    err BAD_DATE "Date not valid"
  }
}
proc validate_time {s} {
  if {![timevalidate %T [string range $s 0 7]]} {
    err BAD_TIME "Time not valid"
  }
}

set first_clear {^(\s*(\#[^\n]*)*)*}
set clear {^(([[:blank:]]*(\#[^\n]*)*(\n|$)[[:blank:]]*)+|$)}
set key_level {([A-Za-z0-9_-]+|\"(?:[^\n\"]|\\\")*\"|\'(?:[^\n\']|\\\')*\')}
set keyt [concat {(} $key_level {([[:blank:]]*\.[[:blank:]]*} $key_level {)*)}]
set key [concat ^ $keyt]
set table [concat {^\[[[:blank:]]*} $keyt {[[:blank:]]*\]}]
set array_of_table [concat {^\[\[[[:blank:]]*} $keyt {[[:blank:]]*\]\]}]
set equal {^[[:blank:]]*(=)[[:blank:]]*}
set str {^(\"([^\n\"]|\\\")*\")}
set str_multiline_only_quotes {^(\"{6,10})}
set str_multiline {^(\"{3}.*?[^\\]\"{3})(?=[^\"]|$)}
set str_literal {^(\'([^\n\'])*\')}
set str_literal_multiline {^(\'{3}.*?\'{3})(?=[^\']|$)}
set boolean {^(true|false)}
set bin {^(0b([0-1]+\_?)*[0-1])}
set oct {^(0o([0-7]+\_?)*[0-7])}
set hex {^(0x([0-9a-fA-F]+\_?)*[0-9a-fA-F])}
set dec {^((\+|\-)?(0|[1-9](\_?[0-9]+)*))}
set nan {^((\+|\-)?nan)}
set inf {^((\+|\-)?inf)}
set float {^((\+|\-)?((0|[1-9](\_?[0-9]+)*)((\.[0-9](\_?[0-9]+)*)|(\.[0-9](\_?[0-9]+)*)?(e|E)(\+|\-)?[0-9](\_?[0-9]+)*)))}
set start_array {^(\[)\s*}
set finish_array {^(\])}
set separate_array {^(,)}
set start_inline_table {^(\{)[[:blank:]]*}
set finish_inline_table {^[[:blank:]]*(\})}
set separate_inline_table {^[[:blank:]]*(,)[[:blank:]]*}
set date {(\d{4}-\d{2}-\d{2})}
set time {(\d{2}:\d{2}:\d{2})(?:\.(\d+))?}
set offset [concat $date {[T|\ ]} $time {(Z|(\-|\+)\d\d:\d\d)}]
set local_date [concat ^ $date]
set local_time [concat ^ $time]
set local_datetime [concat {^(} $date {[T|\ ]} $time {)}]
set offset_datetime [concat {^(} $offset {)}]

proc remove_underscore {s} {
  return [regsub -all {\_} $s {}]
}

proc sub_escape_seq {s} {
  set n $s
  foreach {s f} [lreverse [regexp -all -inline -indices {\\(\s+|u[0-9a-fA-F]{8}|u[0-9a-fA-F]{4}|[btnfr\"\\])} $s]] {
    foreach {fa fb} $f {}
    foreach {sa sb} $s {}
    set lc [string range $n $sa $sb]
    set c [string index $n $sa]
    if {$c == {u}} {
      if {[expr $sb - $sa] == 8} {
        set nc [join "\\U[string range $n [expr $sa + 1] $sb]" ""]
      } else {
        set nc [join "\\u[string range $n [expr $sa + 1] $sb]" ""]
      }
    } elseif {$c in {b t n f r \" \\}} {
      set nc [join "\\$c" ""]
    } else {
      set nc ""
    }
    set n [string replace $n $fa $fb $nc]
  }
  return $n
}

proc handle_str_multiline {raw_s} {
  if {[regexp {([^\\]\"{6,}|\\\"{7,}|\"{10,})$} $raw_s]} {
    err PARSE_ERROR "Sequences of three or more quotes are not permitted"
  }
  set s [sub_escape_seq $raw_s]
  return [huddle string [regsub {^\n} [string range $s 3 end-3] {}]]}

proc handle_str_multiline_only_quotes {raw_s} {
  return [huddle string [string range $raw_s 3 end-3]]}

proc handle_str {raw_s} {
  set s [sub_escape_seq $raw_s]
  return [huddle string [string range $s 1 end-1]]}

proc handle_str_literal_multiline {s} {
  if {![regexp {^(\'{3,5}(.*[^\'])?\'{3,5})$} $s]} {
    err PARSE_ERROR "Sequences of three or more quotes are not permitted"
  }
  return [huddle string [regsub {^\n} [string range $s 3 end-3] {}]]}

proc handle_str_literal {s} {
  return [huddle string [string range $s 1 end-1]]}

proc handle_boolean {s} {
  return [huddle boolean $s]}

proc handle_bin {s} {
  return [huddle number [expr [remove_underscore $s]]]}

proc handle_oct {s} {
  return [huddle number [expr [remove_underscore $s]]]}

proc handle_hex {s} {
  return [huddle number [expr [remove_underscore $s]]]}

proc handle_nan {s} {
  return [huddle nan]}

proc handle_inf {s} {
  if {[string index $s 0] eq {-}} {
    return [huddle -inf]
  }
  return [huddle inf]}

proc handle_float {s} {
  return [huddle number [expr [remove_underscore $s]]]}

proc handle_dec {s} {
  return [huddle number [expr [remove_underscore $s]]]}

proc handle_start_array {s} {
  set arr [huddle list]
  pop first_clear
  while {[pop finish_array] eq ""} {
    huddle append arr [find_value]
    pop first_clear
    if {[pop finish_array] ne ""} {
      break
    } elseif {[pop separate_array] eq ""} {
      err PARSE_ERROR "Undefined separated comma"
    }
    pop first_clear
  }
  return $arr}

proc handle_start_inline_table {s} {
  set d [huddle create]
  while {true} {
    if {[set raw_key [pop key]] eq ""} {
      if {[pop finish_inline_table] ne ""} {
        break
      }
      err PARSE_ERROR "Undefined key"
    }
    set keys [get_keys $raw_key]

    if {[pop equal] eq ""} {
      err PARSE_ERROR "Undefined = or bad key"}

    set value [find_value]

    if {[exists $d $keys]} {
      err OVERWRITE_ERROR {Already defined}
    }

    set d [append_item $keys $value $d]

    if {[pop finish_inline_table] ne ""} {
      break
    } elseif {[pop separate_inline_table] eq ""} {
      err PARSE_ERROR "Undefined separated comma"
    }
  }
  return [huddle protect $d]}

proc handle_local_date {s} {
  validate_date $s
  return [huddle datetime $s]}

proc handle_local_time {s} {
  validate_time $s
  return [huddle datetime $s]}

proc handle_local_datetime {s} {
  set d [string range $s 0 9]
  set t [string range $s 11 18]
  validate_date $d
  validate_time $t
  return [huddle datetime "${d}T[string range $s 11 end]"]}

proc handle_offset_datetime {s} {
  regexp -expanded $::offset $s a d t f o
  validate_date $d
  validate_time $t
  if {$o ne {Z}} {
    if {![timevalidate {%H:%M} [string range $o 1 end]]} {
      err BAD_OFFSET "Offset not valid"
    }
  }
  return [huddle offset_datetime "${d}T[string range $s 11 end]"]}

proc pop {t} {
  set exp [set ::$t]
  set g ""
  if {[regexp -expanded $exp $::raw r g]} {
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
  foreach t {str_multiline_only_quotes str_multiline str str_literal_multiline str_literal boolean \
      offset_datetime local_datetime local_date local_time bin oct hex nan inf float dec start_array start_inline_table} {
    if {[set value [pop $t]] ne ""} {
      return [handle_$t $value]
    }
  }
  err PARSE_ERROR {Undefined value}
}

proc get_keys {path} {
  set l [list]
  foreach {i key} [regexp -expanded -all -inline [concat {[[:blank:]]*} $::key_level {[[:blank:]]*(?:\.|$)}] "$path"] {
    if {[string index $key 0] eq {"}} {
      lappend l [sub_escape_seq [string range $key 1 end-1]]
    } elseif {[string index $key 0] eq {'}} {
      lappend l [string range $key 1 end-1]
    } else {
      lappend l $key
    }
  }
  return $l
}

proc create_parent {tree elem d} {
  set path $tree

  set new_path [list]

  set key [lindex $path end]
  set path [lrange $path 0 end-1]
  while {$path != {}} {

    if {[exists $d $path]} {
      set new_d [huddle get $d {*}[get_path $d $path]]
      if {[huddle type $new_d] != {dict}} {
        err INSERT_ERROR "Insert into non-dict"
      }
      huddle append new_d $key $elem
      huddle set d {*}[get_path $d $path] $new_d
      return $d
    }

    set elem [huddle create $key $elem]
    set key [lindex $path end]
    set path [lrange $path 0 end-1]

    lappend new_path $key
  }
  huddle append d $key $elem

  return $d
}

proc exists {d p} {
  set path [list]
  foreach i $p {
    if {![huddle exists $d $i]} {
      return false
    }
    set d [huddle get $d $i]
    if {[huddle type $d] == {list}} {
      lappend path end
      set d [huddle get $d end]
    }
  }
  return true
}

proc get_path {d p} {
  set path [list]
  foreach i $p {
    lappend path $i
    if {[huddle type $d {*}$path] == {list}} {
      lappend path end
    }
  }
  return $path
}

proc lexists {l1 l2} {
  set i 0
  foreach elem $l1 {
    if {$elem != [lindex $l2 $i]} {
      return false
    }
    incr i
  }
  return true
}

proc open_array_of_table {parents} {
  if {[exists $::dictionary $parents]} {
    if {[huddle type $::dictionary {*}[lrange [get_path $::dictionary $parents] 0 end-1]] != {list}} {
      err INSERT_ERROR {Insert into a non-list}
    }
    set arr [huddle get $::dictionary {*}[lrange [get_path $::dictionary $parents] 0 end-1]]
    huddle append arr [huddle create]
    huddle set ::dictionary {*}[lrange [get_path $::dictionary $parents] 0 end-1] $arr
  } else {
    set ::dictionary [create_parent $parents [huddle list [huddle create]] $::dictionary]
  }
}

proc append_item {full_path value d} {
  set key [lindex $full_path end]
  set path [lrange $full_path 0 end-1]

  if {$path == {}} {
    huddle append d $key $value
  } else {
    if {![exists $d $path]} {
      set d [create_parent $path [huddle create] $d]
    } elseif {[set parent_type [huddle type $d {*}[get_path $d $path]]] != {dict}} {
      if {$parent_type == {protected_dict}} {
        err INSERT_ERROR {Insert into a inline table not allowed}
      }
      err INSERT_ERROR {Insert into a non-dict}
    }
    set parent_dict [huddle get $d {*}[get_path $d $path]]
    huddle append parent_dict $key $value
    huddle set d {*}[get_path $d $path] $parent_dict
  }
  return $d
}

proc decode {raw} {
  set ::history ""
  set parents {}
  set ::dictionary [huddle create]
  set ::raw $raw
  set ::array {}
  set ::array_opened true
  set tables [list]
  set supertables [list]
  set arrays_of_table [list]

  pop first_clear
  set ::history ""
  set is_array_of_table false

  while {$::raw ne ""} {
    if {[set table [pop table]] ne ""} {
      set parents [get_keys $table]
      if {$parents in $tables} {
        err INSERT_ERROR {Tables cannot be defined more than once}
      }

      if {[exists $::dictionary $parents]} {
        if {$parents ni $supertables} {
          err OVERWRITE_ERROR {Already defined}
        }
      }

      set t_keys [lrange $parents 0 end-1]
      while {$t_keys != {}} {
        if {![exists $::dictionary $t_keys]} {
          if {$t_keys ni $supertables} {
            lappend supertables $t_keys
          }
        } else {
          break
        }
        set t_keys [lrange $t_keys 0 end-1]
      }

      lappend tables $parents

      if {![exists $::dictionary $parents]} {
        set ::dictionary [create_parent $parents [huddle create] $::dictionary]
      }

      set is_array_of_table false
    } elseif {[set array_of_table [pop array_of_table]] ne ""} {
      set parents [get_keys $array_of_table]
      if {[exists $::dictionary $parents] && $parents ni $arrays_of_table} {
        err INSERT_ERROR {Insert table into non-array}
      }
      open_array_of_table $parents
      lappend arrays_of_table $parents
      set is_array_of_table true
    } else {
      if {[set raw_key [pop key]] eq ""} {
        err PARSE_ERROR "Undefined key"}
      set keys [get_keys $raw_key]

      if {[set equal [pop equal]] eq ""} {
        err PARSE_ERROR "Undefined = or bad key"}

      set value [find_value]

      if {$is_array_of_table == true} {
        set cur_d [huddle get $::dictionary {*}[get_path $::dictionary $parents]]
        set path $keys
      } else {
        set cur_d $::dictionary
        set path [concat $parents $keys]
      }

      if {[exists $cur_d $path]} {
        err OVERWRITE_ERROR {Already defined}
      }

      set cur_d [append_item $path $value $cur_d]

      if {$is_array_of_table == true} {
        huddle set ::dictionary {*}[get_path $::dictionary $parents] $cur_d
      } else {
        set ::dictionary $cur_d
      }

      if {$is_array_of_table == false} {
        set t_keys $parents
        foreach key [lrange $keys 0 end-1] {
          lappend t_keys $key
          set pos [lsearch $supertables $t_keys]
          if {$pos >= 0} {
            set supertables [lreplace $supertables $pos $pos]
          } else {
            break
          }
        }
      }

    }

    if {[pop clear] eq "" && $::raw ne ""} {
      err PARSE_ERROR "Undefined newline"
    }
    set ::history ""
  }

  return $::dictionary
}
