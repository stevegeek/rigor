require "json"
require "./validator"
require "./document"
require "./vocabulary"

module Rigor
  module Renderer
    extend self

    # The schema permits bare level names, so a value reaching the renderer
    # without prior normalization would miss the code-keyed lookups. Both entry
    # points normalize, but guard anyway rather than risk a KeyError.
    private def level_name(r) : String
      Vocabulary::LEVEL_NAMES[r]? || r
    end

    private def level_def(r) : String
      Vocabulary::LEVEL_DEFINITION[r]? || ""
    end

    private def level_color(r) : String
      Vocabulary::LEVEL_COLOR[r]? || "#6b7280"
    end

    private def vouch_color(v) : String
      Vocabulary::VOUCH_COLOR[v]? || "#6b7280"
    end

    def describe(doc : JSON::Any) : String
      r = doc["rigor"].as_s
      parts = ["Rigor #{r} (#{level_name(r)}) — author's claimed level (#{level_def(r)})."]

      if checks = doc["checks"]?.try(&.as_h?)
        done = Vocabulary::CHECK_KEYS.select { |k| checks[k]?.try(&.as_s) == "yes" }
                                     .map { |k| k.tr("_", " ") }
        parts << "Surfaced checks: #{done.join(", ")}." unless done.empty?
      end

      parts << "Vouch: #{doc["vouch"].as_s}."

      if origin = doc["origin"]?.try(&.as_h?)
        bits = [] of String
        if a = origin["authored"]?.try(&.as_s)
          bits << (Vocabulary::AUTHORED_GLOSS[a]? || a)
        end
        if mnt = origin["maintenance"]?.try(&.as_s)
          bits << (Vocabulary::MAINTENANCE_GLOSS[mnt]? || mnt)
        end
        parts << "Origin: #{bits.join(", ")}." unless bits.empty?
      end

      parts.join(" ")
    end

    def esc(s) : String
      s.to_s.gsub('&', "&amp;").gsub('<', "&lt;").gsub('>', "&gt;").gsub('"', "&quot;")
    end

    # Approx text width: 6.5px per char at 11px font, good enough for layout.
    private def w(text : String, per = 6.5) : Int32
      (text.size * per).ceil.to_i
    end

    def badge(doc : JSON::Any) : String
      r = doc["rigor"].as_s
      v = doc["vouch"].as_s
      left = "rigor #{level_name(r)}"
      right = "vouch #{v}"
      lw = w(left) + 16
      rw = w(right) + 16
      total = lw + rw
      desc = describe(doc)
      <<-SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="#{total}" height="20" role="img" aria-label="#{esc(left)} #{esc(right)}">
        <title>#{esc(left)} | #{esc(right)}</title>
        <desc>#{esc(desc)}</desc>
        <rect width="#{lw}" height="20" rx="3" fill="#{level_color(r)}"/>
        <rect x="#{lw}" width="#{rw}" height="20" fill="#{vouch_color(v)}"/>
        <g font-family="Verdana,Geneva,sans-serif" font-size="11" fill="#fff">
          <text x="8" y="14">#{esc(left)}</text>
          <text x="#{lw + 8}" y="14">#{esc(right)}</text>
        </g>
      </svg>
      SVG
    end

    def infobox(doc : JSON::Any) : String
      r = doc["rigor"].as_s
      v = doc["vouch"].as_s
      width = 340
      desc = describe(doc)
      lines = [] of Tuple(String, Int32, String, String)
      lines << {"Rigor #{r}: #{level_name(r).capitalize}", 16, "bold", "#111"}
      lines << {level_def(r).capitalize, 34, "normal", "#333"}
      lines << {"Vouch: #{v}", 56, "bold", vouch_color(v)}
      voff = 56
      if origin = doc["origin"]?.try(&.as_h?)
        bits = [] of String
        if a = origin["authored"]?.try(&.as_s)
          bits << (Vocabulary::AUTHORED_GLOSS[a]? || a)
        end
        if mnt = origin["maintenance"]?.try(&.as_s)
          bits << (Vocabulary::MAINTENANCE_GLOSS[mnt]? || mnt)
        end
        unless bits.empty?
          voff += 20
          lines << {"Origin: #{bits.join(", ")}", voff, "normal", "#333"}
        end
      end
      height = voff + 22
      texts = lines.map do |(t, y, weight, fill)|
        size = y == 16 ? 13 : 11
        %(<text x="14" y="#{y}" font-family="Verdana,Geneva,sans-serif" font-size="#{size}" font-weight="#{weight}" fill="#{fill}">#{esc(t)}</text>)
      end.join("\n  ")
      <<-SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="#{width}" height="#{height}" role="img" aria-label="Rigor disclosure">
        <title>Rigor #{esc(r)}, vouch #{esc(v)}</title>
        <desc>#{esc(desc)}</desc>
        <rect width="#{width}" height="#{height}" rx="6" fill="#f9fafb" stroke="#{level_color(r)}" stroke-width="2"/>
        #{texts}
      </svg>
      SVG
    end

    def decode_params(params : Hash(String, String)) : Validator::Result
      obj = {} of String => JSON::Any
      obj["rigor"] = JSON::Any.new(Document.normalize_rigor(params["rigor"])) if params.has_key?("rigor")
      obj["vouch"] = JSON::Any.new(params["vouch"]) if params.has_key?("vouch")

      origin = {} of String => JSON::Any
      origin["authored"] = JSON::Any.new(params["authored"]) if params.has_key?("authored")
      origin["maintenance"] = JSON::Any.new(params["maintenance"]) if params.has_key?("maintenance")
      obj["origin"] = JSON::Any.new(origin) unless origin.empty?

      checks = {} of String => JSON::Any
      Vocabulary::CHECK_KEYS.each do |k|
        checks[k] = JSON::Any.new(params[k]) if params.has_key?(k)
      end
      obj["checks"] = JSON::Any.new(checks) unless checks.empty?

      doc = JSON::Any.new(obj)
      struct_errors = Validator.structural(doc)
      return Validator::Result.new(false, struct_errors, [] of String, doc) unless struct_errors.empty?
      sem_errors, warnings = Validator.semantic(doc, strict: false)
      Validator::Result.new(sem_errors.empty?, sem_errors, warnings, doc)
    end

    def invalid_badge(errors : Array(String)) : String
      label = "rigor: invalid"
      lw = w(label) + 16
      desc = "Invalid Rigor badge parameters: #{errors.join("; ")}"
      <<-SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="#{lw}" height="20" role="img" aria-label="#{esc(label)}">
        <title>#{esc(label)}</title>
        <desc>#{esc(desc)}</desc>
        <rect width="#{lw}" height="20" rx="3" fill="#6b7280"/>
        <text x="8" y="14" font-family="Verdana,sans-serif" font-size="11" fill="#fff">#{esc(label)}</text>
      </svg>
      SVG
    end
  end
end
