=begin

= net/snpp.rb

author: Frank Fejes <frank@fejes.net> - 2003-03-18
$Id: snpp.rb,v 1.4 2006-06-10 15:13:55 frank Exp $

This library is free software.
You can freely distribute/modify this library.
There are no warranties.  It may or may not work for you.

= example usage

require 'net/snpp'

your_snpp_server = 'snpp.yourprovider.com'
pager = '123456'
message = 'Hello from Net::SNPP!'

c = Net::SNPP.new(your_snpp_server, 444)
c.send(pager, message) 
c.close

# or

Net::SNPP.new(your_snpp_server, 444) do |c|
  c.send(pager, message) 
end

# or

Net::SNPP.new(your_snpp_server, 444) do |c|
  c.add_pager(pager1)
  c.add_pager(pager2)
  c.message = message
  c.send
end

=end

require 'socket'

module Net

  class SNPP
    SNPP_PORT = 444
    CRLF = "\r\n"

    attr_accessor :debug, :message

    def initialize(host, port = SNPP_PORT)
      @host = host
      @port = port
      @socket = nil
      @pagers = []
      @message = ''
      @debug = false

      return nil if not host
      open(host, port)
      
      if block_given?
        yield self
        close
      end
    end

    def open(host, port = SNPP_PORT)
      @socket = TCPsocket.open(host, port)
      do_cmd_void if not closed?
    end

    def close
      if not closed?
        do_cmd_quit
        @socket.close
      end
    end

    def closed?
      not @socket or @socket.closed?
    end

    def send(pager = nil, message = nil)
      add_pager(pager) if pager

      @message = message if message
      raise SNPPError if not @message
      do_cmd_mess(@message)

      do_cmd_send
    end

    def add_pager(pager)
      do_cmd_page(pager) if pager
    end

    private

    def send_cmd(cmd)
      raise SNPPError if closed?
      cmd = cmd + CRLF
      @socket.write(cmd)
      puts "sent #{cmd}" if @debug
    end

    def do_cmd(cmd)
      send_cmd(cmd)
      status, msg = get_status
      [status, msg]
    end

    def do_cmd_void
      status, msg = get_status
      status =~ /2\d0/ or raise SNPPReplyError, "#{status} #{msg}"
    end

    def do_cmd_page(pager)
      status, msg = do_cmd("PAGE #{pager}")
      status =~ /2\d0/ or raise SNPPReplyError, "#{status} #{msg}"
    end

    def do_cmd_mess(msg)
      msg.gsub!(/\n/, ' ')
      status, msg = do_cmd("MESS #{msg}")
      status =~ /2\d0/ or raise SNPPReplyError, "#{status} #{msg}"
    end

    def do_cmd_send
      status, msg = do_cmd('SEND')
      status =~ /2\d0/ or raise SNPPReplyError, "#{status} #{msg}"
    end

    def do_cmd_quit
      send_cmd('QUIT')
    end

    def do_cmd_reset
      status, msg = do_cmd("RESE")
      status =~ /2\d0/ or raise SNPPReplyError, "#{status} #{msg}"
    end

    def get_reply
      raise SNPPError if closed?
      line = @socket.readline
      if line =~ /(\r?\n|\r)\z/
        line.chop!
      end
      line
    end

    def get_status
      line = get_reply
      line =~ /(\d\d\d)\s+(.+)/ or raise SNPPReplyError, line
      puts "got status %s : %s" % [$1, $2] if @debug
      [$1, $2.chomp]
    end
  end

  class SNPPError < StandardError; end
  class SNPPReplyError < SNPPError; end

end
