#!/usr/bin/env ruby

snpp_gateway = 'snpp.yourprovider.com'

if not ARGV[1]
  puts "usage: #$0 pin message [gateway]"
  exit
end

pager = ARGV[0]
message = ARGV[1]
snpp_gateway = ARGV[2] if ARGV[2]

require 'net/snpp'

c = Net::SNPP.new(snpp_gateway, 444)
c.debug = true
c.send(pager, message) 
c.close
