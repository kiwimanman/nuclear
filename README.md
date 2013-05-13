Nuclear
===

Distributed key value store

How to run:
==

Please install Ruby 2.0.0 and run the following commands to run and see sample behavior:

```
bundle
bundle exec foreman start
bundle exec bin/client
```

Code Structure
----

* /bin
  * Contains scripts that start a master server, a replica server and a basic client.
* /gen-rb
  * Contains generated thrift classes, should not be touched
* /lib
  * Main code line
* /lib/nuclear
  * Base classes that define common objects used by all aspects of the system
  * E.g. transactions, transacation log, storage system
* /lib/nuclear/handlers
  * Classes that implement the RPC interface defined in thrift along with mixins specific to this function.
* /specs
  * Contains unit tests
* /thrift
  * Thrift service definitions
* /
  * Various environment files to make development pleasant

Replica RPC interface
-----



Failure Detection
----

This is mostly done through timeouts. I made a great effort to keep almost all RPC interactions asyncronous including client calls to the master.
The client is only informed of detected failure by requesting the status of the provided transaction id of the original call.

Test Cases
-----

Most in-depth test cases are testing network partion and are done via unit test. Since a network partion can be emulated by simply
not returning asyncronous methods this was simple to simulate. My sample client tries to put to the same key back to back which
helped me find deadlocks, race and concurency issues.
