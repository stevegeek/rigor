require "json"
require "json_schemer"
require "./document"
require "./vocabulary"

module Rigor
  module Validator
    extend self

    # Canonical schema embedded at compile time; keeps the JSON Schema the
    # single source of truth without a runtime file dependency.
    SCHEMA_JSON = {{ read_file("#{__DIR__}/../../rigor.schema.json") }}
    SCHEMER     = JsonSchemer.schema(SCHEMA_JSON)

    def structural(doc : JSON::Any) : Array(String)
      result = SCHEMER.validate(doc)
      return [] of String if result["valid"].as_bool
      result["errors"].as_a.map do |e|
        "#{e["data_pointer"].as_s}: #{clean_message(e["error"].as_s)}"
      end
    end

    # json_schemer prints enum options as `JSON::Any("x")`; unwrap for humans.
    private def clean_message(msg : String) : String
      msg.gsub(/JSON::Any\((".*?")\)/) { $1 }
    end

    record Result,
      valid : Bool,
      errors : Array(String),
      warnings : Array(String),
      doc : JSON::Any?

    def semantic(doc : JSON::Any, strict : Bool) : {Array(String), Array(String)}
      errors = [] of String
      warnings = [] of String

      rigor = doc["rigor"].as_s
      checks = doc["checks"]?.try(&.as_h?) || {} of String => JSON::Any
      required = Vocabulary::LEVEL_REQUIRES[rigor]? || {} of String => Array(String)

      required.each do |name, acceptable|
        if checks.has_key?(name)
          got = checks[name].as_s
          unless acceptable.includes?(got)
            errors << "rigor #{rigor} requires '#{name}' to be one of #{acceptable}, but it is '#{got}'."
          end
        elsif strict
          warnings << "rigor #{rigor} implies '#{name}' but it was not surfaced."
        end
      end

      if origin = doc["origin"]?.try(&.as_h?)
        if origin["maintenance"]?.try(&.as_s) == "ai-auto" && rigor.in?("R3", "R4")
          warnings << "origin.maintenance is 'ai-auto' but rigor is #{rigor}. " \
                      "Fully automated maintenance rarely sustains this level; " \
                      "confirm this reflects review of the most recent changes."
        end
      end

      {errors, warnings}
    end

    def validate(text : String, strict : Bool = false) : Result
      doc, fm_err = Document.extract(text)
      if fm_err
        return Result.new(false, [fm_err], [] of String, nil)
      end
      d = doc.not_nil!

      struct_errors = structural(d)
      unless struct_errors.empty?
        return Result.new(false, struct_errors, [] of String, d)
      end

      sem_errors, warnings = semantic(d, strict)
      Result.new(sem_errors.empty?, sem_errors, warnings, d)
    end
  end
end
