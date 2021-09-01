# modified https://github.com/tcltk/tcllib/blob/a23d722b1faf289d38a1fd22875c9a35c8484d90/modules/yaml/huddle_types.tcl#L4
namespace eval ::huddle::types::protected_dict {
  variable settings 
  
  # type definition
  set settings {publicMethods {protected_dict keys protect} 
                tag P
                isContainer yes
                map {set Set}}

  proc get_subnode {src key} { 
    # get a sub-node specified by "key" from the tagged-content
    return [dict get $src $key]
  }
  
  # strip from the tagged-content
  proc strip {src} {
    foreach {key subnode} $src {
      lappend result $key [strip_node $subnode]
    }
    return $result
  }
  
  # set a sub-node from the tagged-content
  proc Set {src_var key value} {
    error {This is a protected type, you can only create}
  }
  
  proc items {src} {
    set result {}
    dict for {key subnode} $src {
      lappend result [list $key $subnode]
    }
    return $result
  }
  
  # remove a sub-node from the tagged-content
  proc remove {src_var key} {
    error {Protected type object}
  }
  
  proc delete_subnode_but_not_key {src_var key} { 
    error {Protected type object}
  }
  
  # check equal for each node
  proc equal {src1 src2} {
    if {[llength $src1] != [llength $src2]} {return 0}
    foreach {key1 subnode1} $src1 {
      if {![dict exists $src2 $key1]} {return 0}
      if {![are_equal_nodes $subnode1 [dict get $src2 $key1]]} {return 0}
    }
    return 1
  }
  
  proc append_subnodes {tag src list} {
    error {Protected type object}
  }
  
  proc protect {arg} {
    if {![huddle isHuddle $arg] || [huddle type $arg] ne {dict}} {
      error {The arguments must be HUDDLE dictionary}
    }
    lset arg 1 0 P
    return $arg
  }

  # $args: all arguments after "huddle protected_dict"
  proc protected_dict {args} {
      if {[llength $args] % 2} {error {wrong # args: should be "huddle create ?key value ...?"}}
      set resultL [dict create]
      
      foreach {key value} $args {
        if {[isHuddle $key]} {
          foreach {tag src} [unwrap $key] break
          if {$tag ne "string"} {error "The key '$key' must a string literal or huddle string" }
          set key $src    
        }
        dict set resultL $key [argument_to_node $value]
      }
      return [wrap [list P $resultL]]
  }
  
  proc keys {huddle_object} {
    return [dict keys [get_src $huddle_object]]
  }
  
  proc exists {src key} {
    return [dict exists $src $key]
  }

  proc jsondump {huddle_object offset newline nextoff} {
    set nlof "$newline$nextoff"
    set sp " "
    set begin ""

    set inner {}
    foreach {key} [huddle keys $huddle_object] {
        lappend inner [subst {"$key":$sp[huddle jsondump [huddle get $huddle_object $key] $offset $newline $nextoff]}]
    }
    if {[llength $inner] == 1} {
        return $inner
    }
    return "\{$nlof[join $inner ,$nlof]$newline$begin\}"
  }

}

namespace eval ::huddle::types::inf {
  variable settings 
  
  # type definition
  set settings {publicMethods {inf -inf}
                tag inf
                isContainer no }
        
  proc -inf {} {
    return [wrap [list inf -Inf]]
  }

  proc inf {} {
    return [wrap [list inf Inf]]
  }
  
  proc equal {i1 i2} {
    return expr $i1 == $i2
  }

  proc jsondump {huddle_object offset newline nextoff} {
    error "Out of range float values are not JSON compliant"
  }
}

namespace eval ::huddle::types::nan {
  variable settings 
  
  # type definition
  set settings {publicMethods {nan}
                tag nan
                isContainer no }
        
  proc nan {} {
    return [wrap [list nan]]
  }
  
  proc equal {n1 n2} {
    return 1
  }

  proc jsondump {huddle_object offset newline nextoff} {
    error "Out of range float values are not JSON compliant"
  }
}

namespace eval ::huddle::types::offset_datetime {
  variable settings 
  
  # type definition
  set settings {publicMethods {offset_datetime}
                tag odt
                isContainer no }
        
  proc offset_datetime {arg} {
    return [wrap [list odt $arg]]
  }
  
  proc equal {odt1 odt2} {
    return [string equal $odt1 $odt2]
  }

  proc jsondump {huddle_object offset newline nextoff} {
    return [lindex $huddle_object 1 1]
  }
}

namespace eval ::huddle::types::datetime {
  variable settings 
  
  # type definition
  set settings {publicMethods {datetime}
                tag dt
                isContainer no }
        
  proc datetime {arg} {
    return [wrap [list dt $arg]]
  }
  
  proc equal {dt1 dt2} {
    return [string equal $dt1 $dt2]
  }

  proc jsondump {huddle_object offset newline nextoff} {
    return [lindex $huddle_object 1 1]
  }
}

huddle addType ::huddle::types::protected_dict
huddle addType ::huddle::types::inf
huddle addType ::huddle::types::nan
huddle addType ::huddle::types::offset_datetime
huddle addType ::huddle::types::datetime
