namespace eval Unicode {
  variable value

  proc update {c} {
    append Unicode::_s $c
    incr Unicode::_l
    if {$Unicode::_l == 4} {
      return [::Unicode::_result]
    }
    return false
  }

  variable _s ""
  variable _l 0

  proc _clear {} {
    set Unicode::_s ""
    set Unicode::_l 0
  }

  proc _result {} {
    set Unicode::value [format %c "0x$Unicode::_s"]
    Unicode::_clear
    return true
  }
}