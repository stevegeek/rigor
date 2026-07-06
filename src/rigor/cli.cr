require "option_parser"
require "./commands/validate"
require "./commands/embed"
require "./commands/init"
require "./commands/schema"
require "./commands/fmt"

module Rigor::CLI
  extend self

  BANNER = <<-USAGE
    rigor - Rigor/Vouch/Stages disclosure tool

    Usage: rigor <command> [options]

    Commands:
      init      Scaffold a RIGOR.md stamp
      validate  Validate a RIGOR.md (structural + semantic)
      embed     Print the paste-ready README line
      schema    Print the embedded JSON Schema
      fmt       Regenerate the summary from the stamp
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
      vouch_why = nil.as(String?)
      assessed = Time.local.to_s("%Y-%m-%d").as(String?)
      stages = {} of String => Hash(String, String)
      force = false
      dirs = [] of String
      OptionParser.parse(rest) do |p|
        p.on("--rigor V", "Rigor level (default comprehended)") { |x| rigor = x }
        p.on("--vouch V", "Vouch value (default neutral)") { |x| vouch = x }
        p.on("--vouch-why V", "Reason for the vouch (builds the {claim, why} mapping)") { |x| vouch_why = x }
        p.on("--idea-by V", "stages.idea.by") { |x| (stages["idea"] ||= {} of String => String)["by"] = x }
        p.on("--idea-depth V", "stages.idea.depth") { |x| (stages["idea"] ||= {} of String => String)["depth"] = x }
        p.on("--plan-by V", "stages.plan.by") { |x| (stages["plan"] ||= {} of String => String)["by"] = x }
        p.on("--plan-depth V", "stages.plan.depth") { |x| (stages["plan"] ||= {} of String => String)["depth"] = x }
        p.on("--implementation-by V", "stages.implementation.by") { |x| (stages["implementation"] ||= {} of String => String)["by"] = x }
        p.on("--maintenance-by V", "stages.maintenance.by") { |x| (stages["maintenance"] ||= {} of String => String)["by"] = x }
        p.on("--maintenance-activity V", "stages.maintenance.activity") { |x| (stages["maintenance"] ||= {} of String => String)["activity"] = x }
        p.on("--assessed V", "Assessment date YYYY-MM-DD (default today; 'none' to omit)") { |x| assessed = x == "none" ? nil : x }
        p.on("--force", "Overwrite an existing RIGOR.md") { force = true }
        p.unknown_args { |args| dirs = args }
      end
      Commands::Init.run(dirs.first? || ".", rigor, vouch, stages, assessed, force, io, vouch_why)
    when "validate"
      strict = false
      json = false
      readme = nil.as(String?)
      files = [] of String
      OptionParser.parse(rest) do |p|
        p.on("--strict", "Warn on implied-but-unsurfaced checks") { strict = true }
        p.on("--json", "Machine-readable output") { json = true }
        p.on("--readme PATH", "Check PATH's rigor:line block for drift against the stamp") { |x| readme = x }
        p.unknown_args { |args| files = args }
      end
      if files.empty?
        io.puts "usage: rigor validate <file> [--strict] [--json] [--readme PATH]"
        return 2
      end
      Commands::Validate.run(files.first, strict, json, io, readme)
    when "embed"
      files = [] of String
      OptionParser.parse(rest) do |p|
        p.unknown_args { |args| files = args }
      end
      if files.empty?
        io.puts "usage: rigor embed <file>"
        return 2
      end
      Commands::Embed.run(files.first, io)
    when "schema"
      Commands::Schema.run(io)
    when "fmt"
      files = [] of String
      OptionParser.parse(rest) do |p|
        p.unknown_args { |args| files = args }
      end
      if files.empty?
        io.puts "usage: rigor fmt <file>"
        return 2
      end
      Commands::Fmt.run(files.first, io)
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
