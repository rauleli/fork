# TCL Fork Management Library

A lightweight process management library for TCL/TclX that provides structured fork/pipe handling with an object-oriented interface.

## Features

- **Simple Process Creation**: Easy fork management with automatic pipe setup
- **Bidirectional Communication**: Full duplex communication between parent and child processes
- **Event-Driven Architecture**: Asynchronous message handling with configurable callbacks
- **Object-Oriented Interface**: Clean API with configure/cget/send/destroy methods
- **Namespace Isolation**: Each process gets its own isolated namespace
- **Flexible Callbacks**: Configurable handlers for message reception, errors, and connection close

## Requirements

- TCL 8.5+
- TclX extension

## Installation

```tcl
package require fork
```

## Quick Start

### Basic Usage

```tcl
# Create a new child process
set child [::fork::newchild]

# Check if we're in parent or child
if {[$child cget whoami] eq "parent"} {
    puts "I'm the parent process"
    # Send message to child
    $child send "Hello from parent!"
} else {
    puts "I'm the child process"
    # Send message to parent
    $child send "Hello from child!"
}
```

### Named Process Objects

```tcl
# Create a child with a custom command name
set child [::fork::newchild myprocess]

# Now you can use the custom name
myprocess send "Hello world"
puts [myprocess cget whoami]
```

## API Reference

### Process Creation

```tcl
::fork::newchild ?objectName?
```
Creates a new child process and returns a process object handle.

- **objectName** (optional): Custom name for the process command

### Process Object Methods

#### `send data`
Sends data to the connected process (parent→child or child→parent).

```tcl
$child send "Your message here"
```

#### `cget option`
Retrieves process information.

**Options:**
- `whoami`: Returns "parent" or "child"
- `isparent`: Returns 1 if parent process, 0 if child
- `childpid`: Returns child process ID (0 if called from child)

```tcl
puts [$child cget whoami]      ;# "parent" or "child"
puts [$child cget isparent]    ;# 1 or 0
puts [$child cget childpid]    ;# Process ID or 0
```

#### `configure option value ...`
Configures process callbacks.

**Options:**
- `-onget cmd`: Command to execute when receiving data
- `-onclose cmd`: Command to execute when connection closes
- `-onerror cmd`: Command to execute on communication errors

```tcl
$child configure -onget {puts "Received: $data"}
$child configure -onclose {puts "Connection closed"}
$child configure -onerror {puts "Communication error occurred"}
```

#### `destroy`
Closes communication channels and cleans up the process object.

```tcl
$child destroy
```

## Examples

### Echo Server Example

```tcl
package require fork

set child [::fork::newchild]

if {[$child cget whoami] eq "parent"} {
    # Parent: send messages and wait for responses
    $child configure -onget {puts "Child replied: $data"}
    $child send "ping"
    after 1000 {$child send "hello"}
    after 2000 {$child destroy; exit}
    
} else {
    # Child: echo back everything received
    $child configure -onget {
        puts "Child received: $data"
        $child send "echo: $data"
    }
}

# Keep the event loop running
vwait forever
```

### Data Processing Pipeline

```tcl
package require fork

set processor [::fork::newchild dataprocessor]

if {[$processor cget whoami] eq "parent"} {
    # Parent: send data for processing
    $processor configure -onget {puts "Processed result: $data"}
    
    foreach item {apple banana cherry date} {
        $processor send $item
    }
    
} else {
    # Child: process data and send back results
    $processor configure -onget {
        set result [string toupper $data]
        $processor send "PROCESSED: $result"
    }
}

vwait forever
```

## Technical Details

### Communication Protocol
- Uses TCL pipes for inter-process communication
- Line-buffered, non-blocking I/O
- Automatic translation handling
- Event-driven message reception using `fileevent`

### Process Architecture
- Each child process runs in isolated namespace
- Parent maintains references to all child processes
- Automatic cleanup of file descriptors on process termination
- Support for multiple concurrent child processes

## Version History

- **v0.1**: Initial release with basic fork/pipe management

## License

This project is released under the MIT License.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## ☕ Support my work

If this project has been helpful to you or saved you some development time, consider buying me a coffee! Your support helps me keep exploring new optimizations and sharing quality code.

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/rauleli)
## Author

Created by rauleli, Apr 26, 2017
