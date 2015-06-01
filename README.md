RFC2544
=======

RFC2544 network benchmark written in Ruby.

## Usage example:

### Run server on Machine #1:
`ruby core/udp_server.rb`

### Run test script on Machine #2
`ruby run.rb HOST='machine1_ip'`

### Tests:
* Throughput
* Frame loss rate
* Latency (10 sec)

## Dependencies:
* `gem install bindata`
* `ruby >= 2.0`
