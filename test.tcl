source toml.tcl

set d [decode {\
  # This is a full-line comment
  key = "value"  # This is a comment at the end of a line
  another = "# This is not a comment"}]
