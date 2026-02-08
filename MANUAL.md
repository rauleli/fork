# Technical Manual: Tcl Fork Library (v0.2)

This document covers the advanced procedures and internal logic introduced in version 0.2.

## API Reference: `::fork` Namespace

### `::fork::listen_signals`
Sets up signal traps for `SIGTERM`, `SIGINT`, and `SIGQUIT`. 
- **Action**: When any of these signals are received, the library executes `_cleanup`.
- **Effect**: All active child process objects are destroyed, closing their pipes gracefully.

### `::fork::broadcast msg`
Sends a string message to **all** active child processes.
- **Usage**: Useful for global commands like `SHUTDOWN`, `PAUSE`, or `RECONFIG`.
- **Example**: `::fork::broadcast "RELOAD_CONFIG"`

### `::fork::stats`
Returns a summary string of the current library state.
- **Example output**: `"Active children: 3"`

### `::fork::monitor ?interval_ms?`
Starts a background monitoring loop using Tcl's `after`.
- **Interval**: Defaults to 5000ms.
- **Logic**: It checks the existence of pids using `kill -0`. If a process is found to be dead, it triggers the object's `destroy` method, which in turn triggers the `-onclose` callback in the parent.

---

## Process Object API

When you create a child using `set h [::fork::newchild]`, the following methods are available on `$h`:

### Command Execution
- `$h send "text"`: Sends a line to the other end.
- `$h configure -onget {puts "Received: $data"}`: Setup callbacks.
- `$h cget whoami`: Returns context.
- `$h destroy`: Closes pipes and deletes the command.

### Properties (`cget`)
- `isparent`: 1 if this object represents a child managed by a parent.
- `whoami`: "child" or "parent".
- `childpid`: The actual OS PID of the fork (0 when called from within the child context).

---

## Complex Example: Supervisor with Health Checks

```tcl
package require fork 0.2

# 1. Clean shutdown on Ctrl+C or SIGTERM
::fork::listen_signals

# 2. Spawn multiple workers
proc start_worker {name} {
    set h [::fork::newchild $name]
    if {[$h cget isparent]} {
        $h configure -onclose "puts {Worker $name died! Restarting...}; after 1000 {start_worker $name}"
    } else {
        # Worker logic here
        vwait forever
        exit
    }
}

start_worker "http_log"
start_worker "syn_flood"

# 3. Enable periodic process monitoring
::fork::monitor 2000

vwait forever
```
