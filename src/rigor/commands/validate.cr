require "json"
require "../validator"

module Rigor::Commands::Validate
  extend self

  def run(path : String, strict : Bool, json : Bool, io : IO) : Int32
    unless File.exists?(path)
      io.puts "error: no such file: #{path}"
      return 2
    end
    result = Rigor::Validator.validate(File.read(path), strict)

    if json
      spec_version = result.doc.try(&.["spec"]?).try(&.as_s?)
      io.puts({valid: result.valid, errors: result.errors, warnings: result.warnings, spec_version: spec_version}.to_json)
    else
      io.puts "valid: #{result.valid}"
      result.errors.each { |e| io.puts "  error: #{e}" }
      result.warnings.each { |w| io.puts "  warning: #{w}" }
    end

    result.valid ? 0 : 1
  end
end
