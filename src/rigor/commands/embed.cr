require "../validator"
require "../embed"

module Rigor::Commands::Embed
  extend self

  DEFAULT_BASE = "https://rigor.example.dev"

  def run(path : String, base : String, io : IO) : Int32
    result = Rigor::Validator.validate(File.read(path))
    unless result.valid
      io.puts "Cannot generate embed: document is invalid."
      result.errors.each { |e| io.puts "  error: #{e}" }
      return 1
    end
    result.warnings.each { |w| io.puts "  warning: #{w}" }

    out = Rigor::Embed.emit(result.doc.not_nil!, base)
    io.puts "Badge URL:\n  #{out[:badge_url]}\n"
    io.puts "Paste into README (badge, links to full explanation):\n  #{out[:badge_markdown]}\n"
    io.puts "Paste into README (info box):\n  #{out[:infobox_markdown]}\n"
    io.puts "Generated alt text:\n  #{out[:alt]}"
    0
  end
end
