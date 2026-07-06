require "json"
require "json_schemer"
require "./document"
require "./vocabulary"
require "./summary"

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

      # Above the comprehension line, a claim must show its working: the
      # implied checks must be surfaced, not merely non-contradicting. At or
      # below `comprehended`, terse stamps stay legal.
      must_surface = rigor.in?("engineered", "owned")
      required.each do |name, acceptable|
        if checks.has_key?(name)
          got = checks[name].as_s
          unless acceptable.includes?(got)
            errors << "rigor '#{rigor}' requires '#{name}' to be one of #{acceptable}, but it is '#{got}'."
          end
        elsif must_surface
          errors << "rigor '#{rigor}' claims '#{name}' but it is not surfaced — show your working (add '#{name}:' under checks:)."
        elsif strict
          warnings << "rigor '#{rigor}' implies '#{name}' but it was not surfaced."
        end
      end

      # An AI-only review is a different claim from a human one once the
      # headline crosses into engineered/owned territory (below the line the
      # badge's "AI-reviewed" qualifier already covers it). One warning names
      # every affected check, rather than spamming one per check.
      if rigor.in?("engineered", "owned")
        ai_only = %w[quality_reviewed security_reviewed].select { |k| checks[k]?.try(&.as_s) == "ai" }
        unless ai_only.empty?
          names = ai_only.join(" and ")
          warnings << "#{names} satisfied by an AI alone, but rigor is '#{rigor}'. An AI-only " \
                      "review is a different claim from a human one at this level; confirm it " \
                      "supports the claim, or record the human pass."
        end
      end

      if stages = doc["stages"]?.try(&.as_h?)
        if stages["maintenance"]?.try(&.as_h?).try(&.["by"]?).try(&.as_s) == "ai" &&
           rigor.in?("engineered", "owned")
          warnings << "stages.maintenance.by is 'ai' (unattended) but rigor is '#{rigor}'. " \
                      "Fully automated maintenance rarely sustains this level; " \
                      "confirm this reflects review of the most recent changes."
        end

        if maintenance = stages["maintenance"]?.try(&.as_h?)
          if maintenance["by"]?.try(&.as_s) == "none" && maintenance.has_key?("activity")
            errors << "stages.maintenance.by is 'none'; 'activity' does not apply — remove it or name who responds."
          end
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
      if Summary.drift?(text, d)
        sem_errors << "The summary block does not match the stamp. Run `rigor fmt <file>` to regenerate it."
      end
      unless d["spec"]?
        warnings << "The stamp does not declare a spec version. Add `spec: \"0.3\"`."
      end
      Result.new(sem_errors.empty?, sem_errors, warnings, d)
    end
  end
end
