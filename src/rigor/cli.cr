require "option_parser"
require "./commands/validate"
require "./commands/badge"
require "./commands/embed"
require "./commands/serve"
require "./commands/init"
require "./commands/schema"

module Rigor::CLI
  extend self

  BANNER = <<-USAGE
    rigor - Rigor/Vouch/Origin disclosure tool

    Usage: rigor <command> [options]

    Commands:
      init      Scaffold a RIGOR.md stamp
      validate  Validate a RIGOR.md (structural + semantic)
      badge     Render an SVG badge or infobox
      embed     Emit README markdown snippets
      serve     Run the badge HTTP service
      schema    Print the embedded JSON Schema
    USAGE

  def run(argv : Array(String), io : IO = STDOUT) : Int32
    if argv.empty?
      io.puts BANNER
      return 2
    end
    command = argv.first
    rest = argv[1..]

    case command
    when "init"
      rigor = "comprehended"
      vouch = "neutral"
      authored = nil.as(String?)
      maintenance = nil.as(String?)
      force = false
      dirs = [] of String
      OptionParser.parse(rest) do |p|
        p.on("--rigor V", "Rigor level (default comprehended)") { |x| rigor = x }
        p.on("--vouch V", "Vouch value (default neutral)") { |x| vouch = x }
        p.on("--authored V", "origin.authored") { |x| authored = x }
        p.on("--maintenance V", "origin.maintenance") { |x| maintenance = x }
        p.on("--force", "Overwrite an existing RIGOR.md") { force = true }
        p.unknown_args { |args| dirs = args }
      end
      Commands::Init.run(dirs.first? || ".", rigor, vouch, authored, maintenance, force, io)
    when "validate"
      strict = false
      json = false
      files = [] of String
      OptionParser.parse(rest) do |p|
        p.on("--strict", "Warn on implied-but-unsurfaced checks") { strict = true }
        p.on("--json", "Machine-readable output") { json = true }
        p.unknown_args { |args| files = args }
      end
      if files.empty?
        io.puts "usage: rigor validate <file> [--strict] [--json]"
        return 2
      end
      Commands::Validate.run(files.first, strict, json, io)
    when "badge"
      infobox = false
      out_path = nil.as(String?)
      params = nil.as(String?)
      files = [] of String
      OptionParser.parse(rest) do |p|
        p.on("--infobox", "Render the larger infobox") { infobox = true }
        p.on("-o PATH", "--out PATH", "Write SVG to PATH") { |x| out_path = x }
        p.on("--params Q", "Render from a query string instead of a file") { |x| params = x }
        p.unknown_args { |args| files = args }
      end
      Commands::Badge.run(files.first?, params, infobox, out_path, io)
    when "embed"
      base = Commands::Embed::DEFAULT_BASE
      files = [] of String
      OptionParser.parse(rest) do |p|
        p.on("--base URL", "Base URL for the badge service") { |x| base = x }
        p.unknown_args { |args| files = args }
      end
      if files.empty?
        io.puts "usage: rigor embed <file> [--base URL]"
        return 2
      end
      Commands::Embed.run(files.first, base, io)
    when "serve"
      port = 8080
      base = Commands::Embed::DEFAULT_BASE
      bind = Commands::Serve::DEFAULT_BIND
      OptionParser.parse(rest) do |p|
        p.on("--port N", "Port to listen on (default 8080)") { |x| port = x.to_i }
        p.on("--base URL", "Base URL advertised in generated links") { |x| base = x }
        p.on("--bind ADDR", "Address to bind (default 127.0.0.1)") { |x| bind = x }
      end
      Commands::Serve.run(port, base, bind, io)
    when "schema"
      Commands::Schema.run(io)
    when "-h", "--help", "help"
      io.puts BANNER
      0
    when "--version"
      io.puts Rigor::VERSION
      0
    else
      io.puts "unknown command: #{command}"
      io.puts BANNER
      2
    end
  end
end
