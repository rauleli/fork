#
#
#  set objectName [::fork::newchild]
#  ::fork::newchild ?objectName?
#
#  objectName cget whoami|isparent
#  objectName configure -onget|-onclose|-onerror cmd
#  objectName send data
#  objectName destroy
#
#

package require Tclx

namespace eval fork {
  variable id [incr id 0]
  variable pre
  variable pos

  namespace eval child {}

  set pre {
        variable onclose ""
        variable onerror ""
        variable onget   ""
        variable sget
        variable sput
  }
  set pos {
        variable sget
        variable sput
        proc receive   {}     {::fork::_receive}
        proc send      {d}    {::fork::_send}
        proc configure {args} {::fork::_configure}
        proc cget      {arg}  {::fork::_cget}
        proc destroy   {}     {::fork::_destroy}
        fconfigure $sput -blocking 0 -buffering line -translation auto
        fconfigure $sget -blocking 0 -buffering line -translation auto
        fileevent $sget readable [namespace current]::receive
        namespace ensemble create
        namespace export send configure cget destroy
  }

  proc newchild {{name ""}} {
    variable id
    variable pre
    variable pos
    set l [incr id]
    pipe pr pw
    pipe cr cw
    set name [string trimleft $name :]
    foreach x [union [chan names file*] [chan names sock*]] {
      if {[catch {flush $x} err]} {
      }
    }
    if {[set c [fork]]} {
      close $cw
      close $pr
      namespace eval child::$c $pre
      namespace eval child::$c "set sput $pw"
      namespace eval child::$c "set sget $cr"
      namespace eval child::$c $pos
      if {$name ne ""} {
        namespace eval child::$c [list namespace ensemble create -command ::$name]
      }
      return [namespace current]::child::$c
    } else {
      close $cr
      close $pw
      if {[namespace exists ::fork::parent]} {
        namespace eval parent {
          catch {close $sget}
          catch {close $sput}
          namespace delete [namespace current]
        }
      }
      foreach x [namespace children [namespace current]::child] {
        namespace eval $x {
          catch {close $sget}
          catch {close $sput}
          namespace delete [namespace current]
        }
      }
      namespace eval parent $pre
      namespace eval parent "set sget $pr"
      namespace eval parent "set sput $cw"
      namespace eval parent $pos
      if {$name ne ""} {
        namespace eval parent [list namespace ensemble create -command ::$name]
      }
      return [namespace current]::parent
    }
  }

  ##########
  #
  # proc ::fork::_configure
  #
  proc _configure {} {
    uplevel 1 {
      if {[llength $args] % 2} {
        return -code error "Uneven set of parameters"
      } else {
        set c {
          -onget - -onclose - -onerror {
            set v [string range $x 1 e]
            variable $v $y
          }
          default {
            foreach {a b} [lrange $c 0 end-2] {
              lappend d $a
            }
            return -code error "Unrecognized parameter \"$x\".  Valid parameters: [lsort $d]"
          }
        }
        foreach {x y} $args {
          switch -- $x $c
        }
      }
    }
  }

  ##########
  #
  # proc ::fork::_cget
  #
  proc _cget {} {
    uplevel 1 {
      switch -- $arg [set c {
        isparent {
          return [expr {[namespace tail [namespace current]] ne "parent"}]
        }
        whoami {
          if {[namespace tail [namespace current]] eq "parent"} {
            return parent
          } else {
            return child
          }
        }
        childpid {
          if {[cget isparent]} {
            return [namespace tail [namespace current]]
          } else {
            return 0
          }
        }
        default {
          foreach {x y} [lrange $c 0 end-2] {
            lappend z $x
          }
          return -code error "Unrecognized parameter \"$arg\".  Valid parameters: [lsort $z]"
        }
      }]
    }
  }

  ##########
  #
  # proc ::fork::_receive
  #
  proc _receive {} {
    uplevel 1 {
      variable sget
      if {[eof $sget]} {
        variable onclose
        if {$onclose ne ""} {
          uplevel #0 [list $onclose [namespace current]]
        }
        catch {close $sget}
      } elseif {[catch {gets $sget d} err]} {
        variable onerror
        if {$onerror ne ""} {
          uplevel #0 $onerror
        }
      } else {
        variable onget
        if {$onget ne ""} {
          uplevel #0 [list $onget $d]
        } else {
#          puts "receive [namespace current] [pid] [string bytelength $d]"
        }
      }
    }
  }

  ##########
  #
  # proc ::fork::_send
  #
  proc _send {} {
    uplevel 1 {
      variable sput
      if {[catch {puts $sput $d} err]} {
        variable onerror
        if {$onerror ne ""} {
          uplevel #0 $onerror
        } else {
          return -code error $err
        }
      }
    }
  }

  ##########
  #
  # proc ::fork::_destroy
  #
  proc _destroy {} {
    uplevel 1 {
      variable sput
      variable sget
      catch {close $sput}
      catch {close $sget}
      namespace delete [namespace current]
    }
  }
}

package provide fork 0.1

