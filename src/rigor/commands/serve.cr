require "http/server"
require "../server"

module Rigor::Commands::Serve
  extend self

  # Loopback by default: the badge service is a pure, cacheable function of the
  # query string, meant to sit behind a reverse proxy / CDN that terminates the
  # public connection (and enforces request timeouts against slow clients). It
  # connects locally, so binding to 127.0.0.1 keeps the service off the network
  # unless the operator explicitly widens it with --bind.
  DEFAULT_BIND = "127.0.0.1"

  def run(port : Int32, base : String, bind : String, io : IO) : Int32
    handler = Rigor::Server.new(base)
    server = HTTP::Server.new { |ctx| handler.handle(ctx) }
    server.bind_tcp(bind, port)
    io.puts "rigor serve listening on http://#{bind}:#{port} (base=#{base})"
    server.listen
    0
  end
end
