# tcl-toml
A TCL package for parsing and creating TOML

# Requirements
+ tcl
+ tcllib 1.20

# Install
```sh
> echo "package require huddle; puts [package ifneeded huddle 0.3]" | tclsh
source YOUR_PATH

> patch YOUR_PATH huddle.patch
```

# Example
```tcl
package require huddle
source toml.tcl

decode {hello = "world"}
```
