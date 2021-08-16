package require huddle

set first_clear {^(\s*(\#[^\n]*)*)*}
set clear {^(([[:blank:]]*(\#[^\n]*)*(\n|$)[[:blank:]]*)+|$)}
set key_level {([A-Za-z0-9_-]+|\"([^\n\"]|\\\")*\"|\'([^\n\"]|\\\")*\')}
set key_first_lvl [concat ^ $key_level]
set keyt [concat {(} $key_level {([[:blank:]]*\.[[:blank:]]*} $key_level {)*)}]
set key [concat ^ $keyt]
set table [concat {^\[[[:blank:]]*} $keyt {[[:blank:]]*\]}]
set array_of_table [concat {^\[\[[[:blank:]]*} $keyt {[[:blank:]]*\]\]}]
set equal {^[[:blank:]]*(=)[[:blank:]]*}
set str {^(\"([^\n\"]|\\\")*\")}
set str_multiline_only_quotes {^(\"{6,10})}
set str_multiline {^(\"{3}.*?[^\\]\"{3})(?=[^\"]|$)}
set boolean {^(true|false)}
set bin {^(0b([0-1]+\_?)*[0-1])}
set oct {^(0o([0-7]+\_?)*[0-7])}
set hex {^(0x([0-9a-fA-F]+\_?)*[0-9a-fA-F])}
set dec {^((\+|\-)?(0|[1-9](\_?[0-9]+)*))}
set nan {^((\+|\-)?nan)}
set float {^((\+|\-)?((0|[1-9](\_?[0-9]+)*)((\.[0-9](\_?[0-9]+)*)|(\.[0-9](\_?[0-9]+)*)?(e|E)(\+|\-)?[0-9](\_?[0-9]+)*)|inf))}

proc remove_underscore {s} {
  return [regsub -all {\_} $s {}]
}
proc remove_blank_in_key {s} {
  return [regsub -all {[[:blank:]]*\.[[:blank:]]*} $s {.}]
}

proc to_str_multiline {s} {
  if {[regexp {([^\\]\"{6,}|\\\"{7,}|\"{10,})$} $s]} {
    err PARSE_ERROR "Sequences of three or more quotes are not permitted"
  }
  return [string range $s 3 end-3]}
proc to_str_multiline_only_quotes {s} {
  return [string range $s 3 end-3]}
proc to_str {s} {
  return [string range $s 1 end-1]}
proc to_boolean {s} {
  return $s}
proc to_bin {s} {
  return [expr [remove_underscore $s]]}
proc to_oct {s} {
  return [expr [remove_underscore $s]]}
proc to_hex {s} {
  return [expr [remove_underscore $s]]}
proc to_nan {s} {
  return [regsub {nan} $s {NaN}]}
proc to_float {s} {
  return [expr [remove_underscore $s]]}
proc to_dec {s} {
  return [expr [remove_underscore $s]]}

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
  foreach t {str_multiline_only_quotes str_multiline str boolean bin oct hex nan float dec} {
    if {[set value [pop $t]] ne ""} {
      return [to_$t $value]
    }
  }
  err PARSE_ERROR {Undefined value}
}

proc get_level {path l} {
  if {![regexp -expanded [concat $::key_first_lvl {(\.|$)}] $path r lvl]} {
    return $l}
  lappend l $lvl
  return [get_level [string range $path [string length $r] end] $l]
}

proc create_parent {tree} {
  set path $tree

  set new_path [list]
  set d [huddle create]

  set key [lindex $path end]
  set path [lrange $path 0 end-1]
  while {$path != {}} {
    if {[huddle exists $::dictionary {*}$path]} {
      set new_d [huddle get $::dictionary {*}$path]
      huddle append new_d $key $d
      huddle set ::dictionary {*}$path $new_d
      return
    }

    set d [huddle create $key $d]
    set key [lindex $path end]
    set path [lrange $path 0 end-1]

    lappend new_path $key
  }
  huddle append ::dictionary $key $d

  return
}

proc repr {d s} {
  set str ""
  foreach key [huddle keys $d] {
    if {[huddle type $d $key] == {dict}} {
      set str "$str$s$key:\n[repr [huddle get $d $key] "$s  "]"
    } else {
      set str "$str$s$key: [huddle get_stripped $d $key]\n"
    }
  }
  return $str
}

proc create_list {table} {
  if {![huddle exists $::dictionary $path]} {

  } elseif {[huddle type $::dictionary $path] != list} {
    err INSERT_ERROR {Inserting into a non-list}
  }
}

proc decode {raw} {
  set ::history ""
  set parents {}
  set ::dictionary [huddle create]
  set ::raw $raw

  pop first_clear
  set ::history ""

  while {$::raw ne ""} {
    if {[set table [remove_blank_in_key [pop table]]] ne ""} {
      puts "Table: $table"

      set parents [get_level $table [list]]
      if {[huddle exists $::dictionary {*}$parents]} {
        err OVERWRITE_ERROR {Already defined}
      }
      create_parent $parents
    } elseif {[set array_of_table [remove_blank_in_key [pop array_of_table]]] ne ""} {
      puts "Array of table: $array_of_table"

      set parents [get_level $array_of_table [list]]
      if {[huddle exists $::dictionary {*}$parents]} {
        if {[huddle type $::dictionary {*}$parents] != {list}} {
          err INSERT_ERROR {Inserting into a non-list}
        }
      }
      create_list $parents

    } else {
      if {[set raw_key [remove_blank_in_key [pop key]]] eq ""} {
        err PARSE_ERROR "Undefined key"}
      puts "Key: $raw_key"
      set keys [get_level $raw_key [list]]
      set key [lindex $keys end]
      set path [concat $parents [lrange $keys 0 end-1]]

      if {[set equal [pop equal]] eq ""} {
        err PARSE_ERROR "Undefined = or bad key"}

      if {[huddle exists $::dictionary {*}$path $key]} {
        err OVERWRITE_ERROR {Already defined}
      }

      set value [find_value]
      puts "Value: $value"
      if {$path == {}} {
        huddle append ::dictionary $key [huddle string $value]
      } else {
        if {![huddle exists $::dictionary {*}$path]} {
          create_parent $path
        } elseif {[huddle type $::dictionary {*}$path] != {dict}} {
          err INSERT_ERROR {Inserting into a non-dict}
        }
        set parent_dict [huddle get $::dictionary {*}$path]
        huddle append parent_dict $key [huddle string $value]
        huddle set ::dictionary {*}$path $parent_dict
      }
    }
    if {[set clear [pop clear]] eq "" && $::raw ne ""} {
      err PARSE_ERROR "Undefined newline"}
    set ::history ""
  }

  puts [repr $::dictionary ""]
}
