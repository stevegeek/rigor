require "json"
require "./vocabulary"

module Rigor
  # Deterministic stamp emission. Hand-rolled (not YAML.dump) so key order,
  # flow style, and quoting are stable — fmt must be idempotent byte-for-byte.
  module StampYAML
    extend self

    def emit(doc : JSON::Any) : String
      out = String.build do |io|
        io << "spec: \"" << (doc["spec"]?.try(&.as_s) || "0.2") << "\"\n"
        io << "rigor: " << doc["rigor"].as_s << "\n"
        io << "vouch: " << doc["vouch"].as_s << "\n"
        if checks = doc["checks"]?.try(&.as_h?)
          io << "checks:\n"
          Vocabulary::CHECK_KEYS.each do |k|
            io << "  " << k << ": " << checks[k].as_s << "\n" if checks.has_key?(k)
          end
        end
        if stages = doc["stages"]?.try(&.as_h?)
          io << "stages:\n"
          Vocabulary::STAGE_KEYS.each do |k|
            next unless st = stages[k]?.try(&.as_h?)
            fields = [] of String
            fields << "by: #{st["by"].as_s}" if st.has_key?("by")
            fields << "depth: #{st["depth"].as_s}" if st.has_key?("depth")
            io << "  " << k << ": {" << fields.join(", ") << "}\n" unless fields.empty?
          end
        end
        if assessed = doc["assessed"]?.try(&.as_s)
          io << "assessed: " << assessed << "\n"
        end
        if notes = doc["notes"]?.try(&.as_s)
          io << "notes: " << notes.to_json << "\n"
        end
      end
      out
    end
  end
end
