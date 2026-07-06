require "json"
require "../validator"
require "../summary"

module Rigor::Commands::Validate
  extend self

  def run(path : String, strict : Bool, json : Bool, io : IO, readme : String? = nil) : Int32
    unless File.exists?(path)
      io.puts "error: no such file: #{path}"
      return 2
    end
    result = Rigor::Validator.validate(File.read(path), strict)

    errors = result.errors
    valid = result.valid

    if readme && File.exists?(readme) && (doc = result.doc) && Rigor::Validator.structural(doc).empty?
      if Rigor::Summary.line_drift?(File.read(readme), doc)
        errors = errors + ["The README line does not match the stamp. Run rigor embed and re-paste."]
        valid = false
      end
    end

    if json
      spec_version = result.doc.try(&.["spec"]?).try(&.as_s?)
      io.puts({valid: valid, errors: errors, warnings: result.warnings, spec_version: spec_version}.to_json)
    else
      io.puts "valid: #{valid}"
      errors.each { |e| io.puts "  error: #{e}" }
      result.warnings.each { |w| io.puts "  warning: #{w}" }
    end

    valid ? 0 : 1
  end
end
