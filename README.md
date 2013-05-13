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

* oneway void      put(1:string key, 2:string value, 3:string transaction_id),
  * Manditory method, async as the master doesn't need to know the status
* string      get(1:string key),
  * Manditory method, syncronous due to the master needing to pass back the true value to the client
* oneway void   remove(1:string key, 2:string transaction_id),
  * Manditory method, async as the master doesn't need to know the status
* oneway void  votereq(1:string transaction_id),
  * By keeping this call to vote seperate from a transaction itself this allows for more complicated sequences in the future.
* oneway void finalize(1:string transaction_id, 2:Status decision)
  * Hook to allow a master to finish the transaction and commit to the replica.
* Status   status(1:string transaction_id)
  * Enabled gossip protocols

Failure Detection
----

This is mostly done through timeouts. I made a great effort to keep almost all RPC interactions asyncronous including client calls to the master.
The client is only informed of detected failure by requesting the status of the provided transaction id of the original call.

Test Cases
-----

Most in-depth test cases are testing network partion and are done via unit test. Since a network partion can be emulated by simply
not returning asyncronous methods this was simple to simulate. My sample client tries to put to the same key back to back which
helped me find deadlocks, race and concurency issues.
