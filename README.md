transformator
=============

transformator is a event-based server for compiling jade-lang and various
other languages.

# Supported languages and filters

transformator uses jade, minify and transformers. transformers is a wrapper
library for many languages.

# How it works

transformator creates a socket (tcp or unix domain) and listens for
requests.  The protocol is very simple: for each request a connection must
be made.  Any request is a fixed-length CBOR array with three elements: name
of the engine to be used, input string and a optional object containing
data.  The third element is only relevant for jade. 

transformator then returns a CBOR hash object either with a single key `result`
containing the resulting output string or a single key `error` containing an
error message. The connection will be immediately closed.

# How to use

transformator comes as a command-line tool called `transformator`. It
accepts three forms of arguments:

+ `<port-number>`

  Bind the socket to localhost and listen at specifed port

+ `<bind-address>` `<port-number>`

  Bind the socket to specified address/hostname

+ `<path/to/unix/domain/socket>`

  Do not use TCP/IP but unix domain socket

# Client libraries

+ Perl

  [Net::NodeTransformator](https://metacpan.org/pod/Net::NodeTransformator)
