require "../validator"
require "../embed"

module Rigor::Commands::Embed
  extend self

  def run(path : String, io : IO) : Int32
    result = Rigor::Validator.validate(File.read(path))
    unless result.valid
      io.puts "Cannot generate embed: document is invalid."
      result.errors.each { |e| io.puts "  error: #{e}" }
      return 1
    end
    result.warnings.each { |w| io.puts "  warning: #{w}" }

    io.puts Rigor::Embed.emit(result.doc.not_nil!)
    io.puts
    io.puts Rigor::Embed::USAGE_HINT
    0
  end
end
