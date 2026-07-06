require "./spec_helper"
require "http/client"

describe Rigor::Server do
  it "serves a badge SVG with cache headers for valid params" do
    server = HTTP::Server.new { |ctx| Rigor::Server.new("http://localhost").handle(ctx) }
    address = server.bind_unused_port
    spawn { server.listen }
    Fiber.yield

    begin
      res = HTTP::Client.get("http://#{address}/badge.svg?rigor=comprehended&vouch=neutral")
      res.status_code.should eq(200)
      res.headers["Content-Type"].should eq("image/svg+xml")
      res.headers["Cache-Control"].should contain("max-age")
      res.body.should contain(">comprehended<")
      res.body.should contain(">no vouch<")

      bad = HTTP::Client.get("http://#{address}/badge.svg?rigor=R9&vouch=yes")
      bad.status_code.should eq(400)
      bad.body.should contain("rigor: invalid")
    ensure
      server.close
    end
  end
end
