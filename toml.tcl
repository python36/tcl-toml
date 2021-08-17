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

proc create_parent {tree elem d} {
  # set d [huddle create]
  set path $tree

  set new_path [list]

  set key [lindex $path end]
  set path [lrange $path 0 end-1]
  while {$path != {}} {
    if {[exists $d $path]} {
      set new_d [huddle get $d {*}[get_path $d $path]]
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

proc repr {d s} {
  set str ""
  foreach key [huddle keys $d] {
    if {[huddle type $d $key] == {dict}} {
      set str "$str$s$key: \{\n[repr [huddle get $d $key] "$s  "]$s\}\n"
    } elseif {[huddle type $d $key] == {list}} {
      set l [huddle get $d $key]
      set str "$str$s$key: \[\n"
      for {set i 0} {$i < [huddle llength $l]} {incr i} {
        set str "$str[repr [huddle get $d $key $i] "$s  "],"
      }
      set str "$str$s\]\n"
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

proc exists {d p} {
  set path [list]
  foreach i $p {
    puts "%%%$path [huddle exists $d a b] $d"
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

proc decode {raw} {
  set ::history ""
  set parents {}
  set ::dictionary [huddle create]
  set ::raw $raw

  pop first_clear
  set ::history ""
  set is_table false

  while {$::raw ne ""} {
    if {[set table [remove_blank_in_key [pop table]]] ne ""} {
      puts "Table: $table"

      set parents [get_level $table [list]]
      if {[exists $::dictionary $parents]} {
        err OVERWRITE_ERROR {Already defined}
      }
      set ::dictionary [create_parent $parents [huddle create] $::dictionary]
      set is_table false
    } elseif {[set array_of_table [remove_blank_in_key [pop array_of_table]]] ne ""} {
      puts "Array of table: $array_of_table"

      set parents [get_level $array_of_table [list]]
      puts "ARR[exists $::dictionary $parents]"

      puts "^^^$parents, $::dictionary"
      if {[exists $::dictionary $parents]} {
        puts ")))_+++++++++++++++++++++[get_path $::dictionary $parents]"
        if {[huddle type $::dictionary {*}[lrange [get_path $::dictionary $parents] 0 end-1]] != {list}} {
          err INSERT_ERROR {Inserting into a non-list}
        }
        set arr [huddle get $::dictionary {*}[lrange [get_path $::dictionary $parents] 0 end-1]]
        puts "???$arr"
        huddle append arr [huddle create]
        huddle set ::dictionary {*}[lrange [get_path $::dictionary $parents] 0 end-1] $arr
      } else {
        puts "!!!$::dictionary==$parents"
        set ::dictionary [create_parent $parents [huddle list [huddle create]] $::dictionary]
        puts "!!!$::dictionary"
      }

      puts "***$::dictionary"
      set is_table true

    } else {
      if {[set raw_key [remove_blank_in_key [pop key]]] eq ""} {
        err PARSE_ERROR "Undefined key"}
      puts "Key: $raw_key"
      set keys [get_level $raw_key [list]]
      set key [lindex $keys end]

      if {[set equal [pop equal]] eq ""} {
        err PARSE_ERROR "Undefined = or bad key"}

      set value [find_value]
      puts "Value: $value"


      if {$is_table == true} {
        puts "###[get_path $::dictionary $parents]"
        set cur_d [huddle get $::dictionary {*}[get_path $::dictionary $parents]]
        puts "&&&$cur_d"
        set path [lrange $keys 0 end-1]
      } else {
        set cur_d $::dictionary
        set path [concat $parents [lrange $keys 0 end-1]]
      }

      # puts $cur_d
      # puts "++[huddle exists $cur_d {*}$path $key]"

      if {[exists $cur_d [concat $path $key]]} {
        err OVERWRITE_ERROR {Already defined}
      }

      puts "---$path"
      if {$path == {}} {
        huddle append cur_d $key [huddle string $value]
      } else {
        if {![exists $cur_d $path]} {
          set cur_d [create_parent $path [huddle create] $cur_d]
          puts "-/-$cur_d $path"
        } elseif {[huddle type $cur_d {*}[get_path $cur_d $path]] != {dict}} {
          err INSERT_ERROR {Inserting into a non-dict}
        }
        puts "-+=$cur_d"
        set parent_dict [huddle get $cur_d {*}[get_path $cur_d $path]]
        huddle append parent_dict $key [huddle string $value]
        huddle set cur_d {*}[get_path $cur_d $path] $parent_dict
      }



      if {$is_table == true} {
        huddle set ::dictionary {*}[get_path $::dictionary $parents] $cur_d
      } else {
        set ::dictionary $cur_d
      }




    }
    if {[set clear [pop clear]] eq "" && $::raw ne ""} {
      err PARSE_ERROR "Undefined newline"}
    set ::history ""
  }

  puts [repr $::dictionary ""]
}
