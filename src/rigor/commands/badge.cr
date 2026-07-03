require "uri"
require "../renderer"

module Rigor::Commands::Badge
  extend self

  def run(path : String?, params : String?, infobox : Bool, out_path : String?, io : IO) : Int32
    result =
      if path
        Rigor::Validator.validate(File.read(path))
      elsif params
        Rigor::Renderer.decode_params(parse_query(params))
      else
        io.puts "usage: rigor badge <file> | --params \"rigor=..&vouch=..\""
        return 2
      end

    svg =
      if result.valid && (doc = result.doc)
        infobox ? Rigor::Renderer.infobox(doc) : Rigor::Renderer.badge(doc)
      else
        Rigor::Renderer.invalid_badge(result.errors)
      end

    if out_path
      File.write(out_path, svg)
      io.puts "wrote #{out_path}"
    else
      io.puts svg
    end
    result.valid ? 0 : 1
  end

  private def parse_query(q : String) : Hash(String, String)
    h = {} of String => String
    q.split('&').each do |pair|
      next if pair.empty?
      k, _, v = pair.partition('=')
      h[k] = URI.decode_www_form(v)
    end
    h
  end
end
