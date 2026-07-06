require "../validator"
require "../summary"
require "../stamp_yaml"

module Rigor::Commands::Fmt
  extend self

  def run(path : String, io : IO) : Int32
    unless File.exists?(path)
      io.puts "error: no such file: #{path}"
      return 2
    end
    text = File.read(path)
    doc, err = Rigor::Document.extract(text)
    if err
      io.puts "error: #{err}"
      return 1
    end
    d = doc.not_nil!

    struct_errors = Rigor::Validator.structural(d)
    unless struct_errors.empty?
      io.puts "error: stamp is structurally invalid; fix it before formatting:"
      struct_errors.each { |e| io.puts "  #{e}" }
      return 1
    end

    new_text = Rigor::Summary.replace(text, d) || insert_summary(text, d)
    File.write(path, new_text)

    io.puts "wrote #{path}"
    0
  end

  # No markers yet: put the summary block right after the title line.
  private def insert_summary(text : String, doc) : String
    lines = text.split('\n')
    lines.insert(1, "\n#{Rigor::Summary.block(doc)}")
    lines.join('\n')
  end
end
