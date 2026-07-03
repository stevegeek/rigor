require "../vocabulary"

module Rigor::Commands::Init
  extend self

  def run(dir : String, rigor : String, vouch : String, authored : String?, maintenance : String?, force : Bool, io : IO) : Int32
    path = File.join(dir, "RIGOR.md")
    if File.exists?(path) && !force
      io.puts "error: #{path} already exists (use --force to overwrite)"
      return 1
    end

    origin_block =
      if authored || maintenance
        lines = ["origin:"]
        lines << "  authored: #{authored}" if authored
        lines << "  maintenance: #{maintenance}" if maintenance
        lines.join("\n") + "\n"
      else
        <<-YAML
        # origin:            # optional provenance trajectory
        #   authored: ai-assisted        # human-crafted | ai-assisted | ai-generated
        #   maintenance: human-led       # human-led | ai-led | ai-auto

        YAML
      end

    File.write(path, <<-MD)
    ---
    rigor: #{rigor}
    vouch: #{vouch}
    # checks:              # optional; surface any subset. security_reviewed is the one to show.
    #   comprehended: yes
    #   quality_reviewed: yes
    #   security_reviewed: yes
    #   tested: not-applicable
    #   owned: yes
    #{origin_block}---

    # Rigor, Vouch, Origin

    One-line restatement for anyone reading this file directly.

    ## Notes

    Why the level is what it is, what was and was not checked.
    MD

    io.puts "wrote #{path}"
    0
  end
end
