# Async Rails Test

Edge Rails (as of 2/5/2022) now has a [Fiber-safe ActiveRecord::ConnectionPool](https://github.com/rails/rails/pull/44219).

This is a simple Rails server that demonstrates how Edge Rails can be used in conjunction
with the highly concurrent, Fiber-based [Falcon web server](https://github.com/socketry/falcon).

With the Ruby 3.1 Fiber scheduler, any Ruby IO
(and any C extensions that have made the necessary changes to support the Fiber scheduler,
including the `pg` Postgres gem) can now be efficiently scheduled onto the Fiber Scheduler,
allowing these IO operations to be performed concurrently. Previous
versions of the Async gem required use of a variety of different Async-specific gems to
get this to work, but now a vast majority of common/mainstream gems work in a
Fiber-friendly concurrent manner out of the box. And with a Fiber-safe connection pool,
now ActiveRecord queries can be made concurrently with a Fiber-centric server like Falcon.

The following text is a sample rendering of the
[application#index](./app/controllers/application_controller.rb) route.
What it demonstrates is that multiple concurrent operations that each
take about a second to complete all finish within ~1.5s (it would be
closed to 1 but my internet is slow and I'm hitting an external HTTP server).

```
Falcon Rails test
Results of concurrent fetch
Elapsed time: 1.49s

Kernel#sleep(1) 0: 1
Kernel#sleep(1) 1: 1
Kernel#sleep(1) 2: 1
HTTParty 0: 200 OK
HTTParty 1: 200 OK
HTTParty 2: 200 OK
Postgres pg_sleep(1) 0: #<PG::Result:0x000000010d157eb8>
Postgres pg_sleep(1) 1: #<PG::Result:0x000000010d154dd0>
Postgres pg_sleep(1) 2: #<PG::Result:0x000000010d15e3d0>
redis push after Kernel#sleep: 1
redis blocking pop: ["queue", "2"]

Log

0.0s Kernel#sleep(1) 0 starting on Fiber 94300
0.0s Kernel#sleep(1) 1 starting on Fiber 94340
0.0s Kernel#sleep(1) 2 starting on Fiber 94380
0.0s HTTParty 0 starting on Fiber 94420
0.0s HTTParty 1 starting on Fiber 94460
0.0s HTTParty 2 starting on Fiber 94500
0.0s Postgres pg_sleep(1) 0 starting on Fiber 94540
0.01s Postgres pg_sleep(1) 1 starting on Fiber 94560
0.01s Postgres pg_sleep(1) 2 starting on Fiber 94580
0.01s redis push after Kernel#sleep starting on Fiber 94600
0.01s redis blocking pop starting on Fiber 94640
1.0s Kernel#sleep(1) 0 done in
1.0s Kernel#sleep(1) 1 done in
1.0s Kernel#sleep(1) 2 done in
1.01s Postgres pg_sleep(1) 0 done in
1.01s redis blocking pop done in
1.01s redis push after Kernel#sleep done in
1.01s Postgres pg_sleep(1) 1 done in
1.01s Postgres pg_sleep(1) 2 done in
1.47s HTTParty 2 done in
1.47s HTTParty 0 done in
1.49s HTTParty 1 done in
```

## Requirements

The main requirements to get something like this working on your server:

1. Edge Rails (hopefully they'll have an official release soon that includes Fiber-safe connection pool)
1. Latest version of Falcon
1. Latest version of Async
1. Latest version of pg Postgres gem (with support for Ruby 3.1 Fiber Scheduler)
1. Ruby 3.1+ (which includes refinements to the Ruby Fiber Scheduler interface)

Add the following to config/application.rb:

```rb
config.active_support.isolation_level = :fiber
```

