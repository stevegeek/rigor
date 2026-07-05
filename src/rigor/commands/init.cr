require "json"
require "../vocabulary"
require "../summary"
require "../stamp_yaml"
require "../validator"

module Rigor::Commands::Init
  extend self

  def run(dir : String, rigor : String, vouch : String,
          stages : Hash(String, Hash(String, String)), assessed : String?,
          force : Bool, io : IO) : Int32
    path = File.join(dir, "RIGOR.md")
    if File.exists?(path) && !force
      io.puts "error: #{path} already exists (use --force to overwrite)"
      return 1
    end

    obj = {} of String => JSON::Any
    obj["spec"] = JSON::Any.new("0.2")
    obj["rigor"] = JSON::Any.new(Rigor::Document.normalize_rigor(rigor))
    obj["vouch"] = JSON::Any.new(vouch)
    unless stages.empty?
      st = {} of String => JSON::Any
      Vocabulary::STAGE_KEYS.each do |k|
        next unless fields = stages[k]?
        st[k] = JSON::Any.new(fields.transform_values { |v| JSON::Any.new(v) })
      end
      obj["stages"] = JSON::Any.new(st)
    end
    obj["assessed"] = JSON::Any.new(assessed) if assessed
    doc = JSON::Any.new(obj)

    errors = Rigor::Validator.structural(doc)
    if errors.empty?
      sem_errors, _ = Rigor::Validator.semantic(doc, strict: false)
      errors = sem_errors
    end
    unless errors.empty?
      io.puts "error: refusing to write an invalid stamp:"
      errors.each { |e| io.puts "  #{e}" }
      return 1
    end

    File.write(path, <<-MD)
    # About this code

    #{Rigor::Summary.block(doc)}

    ## Notes

    Why the level is what it is, what was and was not checked, and anything
    the plain summary above cannot carry.

    ## Stamp

    ```yaml
    #{Rigor::StampYAML.emit(doc)}```

    <!--
    checks: surface any subset under the stamp; done-values carry the actor.
      comprehended: yes | no          (can a human explain every line?)
      quality_reviewed / security_reviewed / tested: human | ai | human-with-ai | yes | no | not-applicable
      owned: yes | no                 (architectural responsibility)
    Run `rigor fmt RIGOR.md` after editing the stamp to refresh the summary.
    -->
    MD

    io.puts "wrote #{path}"
    0
  end
end
