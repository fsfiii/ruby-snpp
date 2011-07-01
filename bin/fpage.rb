#!/usr/bin/env ruby

=begin

= fpage.rb

author: Frank Fejes <frank@fejes.net> - 2003-03-21
$Id: fpage.rb,v 1.3 2006-06-10 15:13:27 frank Exp $

This is free software.
You can freely distribute/modify this program.
There are no warranties.  It may or may not work for you.

=end

require 'net/snpp'
require 'getoptlong'

def usage(opts)
  puts "usage: #$0 [options] message ..."
  puts "required options:"
  puts "  -g, --gateway GATEWAY"
  puts "  -p, --pin, --pager, --to PIN (specify more than once for multiple)"
  puts "other options:"
  puts "  -h, --help"
  puts "  -d, --debug                        [#{opts['debug']}]"
  puts "      --port PORT                    [#{opts['port']}]"
  puts "  -f, --from FROM                    [#{opts['from']}]"
end

# defaults

config = {}
config['port'] = Net::SNPP::SNPP_PORT
config['debug'] = false
config['gateway'] = nil
config['pins'] = []
config['from'] = `whoami`.chomp

opts = GetoptLong.new(
  ['--port', GetoptLong::REQUIRED_ARGUMENT],
  ['--debug', '-d', GetoptLong::NO_ARGUMENT],
  ['--help', '-h', GetoptLong::NO_ARGUMENT],
  ['--gateway', '-g', GetoptLong::REQUIRED_ARGUMENT],
  ['--from', '-f', GetoptLong::REQUIRED_ARGUMENT],
  ['--pin', '--to', '--pager', '-p', GetoptLong::REQUIRED_ARGUMENT]
)

begin
  opts.each do |opt, arg|
    # puts "#{opt} : #{arg}"
    case opt
      when /--port/ ; config['port'] = arg.to_i
      when /--debug/ ; config['debug'] = true
      when /--gateway/ ; config['gateway'] = arg
      when /--from/ ; config['from'] = arg
      when /--pin/ ; config['pins'].push(arg)
      when /--help/ ; usage(config); exit
    end
  end
rescue GetoptLong::MissingArgument, GetoptLong::InvalidOption => detail
  exit
end

msg = ARGV.join(' ')
if msg.length < 1
  usage(config)
  exit 1
end
msg += " - #{config['from']}"

if not config['gateway'] or config['pins'].length < 1
  usage(config)
  exit 1
end

# more declarative way
#snpp = Net::SNPP.new(config['gateway'], config['port'])
#snpp.debug = true if config['debug']
#config['pins'].each do |pin|
#  begin
#    snpp.add_pager(pin)
#  rescue Net::SNPPReplyError => detail
#    puts detail
#  end
#end
#snpp.send(nil, msg)
#snpp.close

# or

# more oop ruby way
Net::SNPP.new(config['gateway'], config['port']) do |snpp|
  snpp.debug = true if config['debug']
  config['pins'].each do |pin|
    begin
      snpp.add_pager(pin)
    rescue Net::SNPPReplyError => detail
      puts detail
    end
  end
  snpp.message = msg
  snpp.send
end
