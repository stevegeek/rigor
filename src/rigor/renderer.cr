require "json"
require "./validator"
require "./document"
require "./vocabulary"
require "./summary"

module Rigor
  module Renderer
    extend self

    private def level_def(r) : String
      Vocabulary::LEVEL_GLOSS[r]? || ""
    end

    private def level_color(r) : String
      Vocabulary::LEVEL_COLOR[r]? || "#6b7280"
    end

    private def vouch_color(v) : String
      Vocabulary::VOUCH_COLOR[v]? || "#6b7280"
    end

    def describe(doc : JSON::Any) : String
      Summary.compose(doc)
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
      left = r
      left += " · AI-reviewed" if !Vocabulary::ABOVE_LINE.includes?(r) && ai_reviewed?(doc)
      right = Vocabulary::VOUCH_LABEL[v]? || v
      label = "#{left} | #{right}"
      lw = w(left) + 16
      rw = w(right) + 16
      total = lw + rw
      desc = describe(doc)
      <<-SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="#{total}" height="20" role="img" aria-label="#{esc(label)}">
        <title>#{esc(label)}</title>
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

    # A below-the-line stamp whose review checks were AI-performed is a
    # different claim from a raw skim; surface it at badge resolution.
    private def ai_reviewed?(doc : JSON::Any) : Bool
      checks = doc["checks"]?.try(&.as_h?) || return false
      %w[quality_reviewed security_reviewed].any? { |k| checks[k]?.try(&.as_s) == "ai" }
    end

    def infobox(doc : JSON::Any) : String
      r = doc["rigor"].as_s
      v = doc["vouch"].as_s
      width = 340
      desc = describe(doc)
      lines = [] of Tuple(String, Int32, String, String)
      lines << {"Rigor: #{r.capitalize}", 16, "bold", "#111"}
      lines << {level_def(r).capitalize, 34, "normal", "#333"}
      lines << {"Vouch: #{Vocabulary::VOUCH_LABEL[v]? || v}", 56, "bold", vouch_color(v)}
      voff = 56
      if stages = doc["stages"]?.try(&.as_h?)
        bits = [] of String
        Vocabulary::STAGE_KEYS.each do |k|
          next unless st = stages[k]?.try(&.as_h?)
          by = st["by"]?.try(&.as_s)
          depth = st["depth"]?.try(&.as_s)
          desc = [by ? Vocabulary::BY_SHORT[by]? || by : nil,
                  depth ? Vocabulary::DEPTH_SHORT[depth]? || depth : nil].compact.join(", ")
          bits << "#{Vocabulary::STAGE_LABEL[k]}: #{desc}" unless desc.empty?
        end
        bits.each do |bit|
          voff += 20
          lines << {"#{bit}", voff, "normal", "#333"}
        end
      end
      height = voff + 22
      texts = lines.map do |(t, y, weight, fill)|
        size = y == 16 ? 13 : 11
        %(<text x="14" y="#{y}" font-family="Verdana,Geneva,sans-serif" font-size="#{size}" font-weight="#{weight}" fill="#{fill}">#{esc(t)}</text>)
      end.join("\n  ")
      <<-SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="#{width}" height="#{height}" role="img" aria-label="Rigor disclosure">
        <title>Rigor #{esc(r)}, #{esc(Vocabulary::VOUCH_LABEL[v]? || v)}</title>
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

      stages = {} of String => JSON::Any
      {"idea" => %w[idea_by idea_depth], "plan" => %w[plan_by plan_depth],
       "implementation" => %w[implementation_by], "maintenance" => %w[maintenance_by]}.each do |stage, keys|
        st = {} of String => JSON::Any
        keys.each do |pk|
          field = pk.ends_with?("_depth") ? "depth" : "by"
          st[field] = JSON::Any.new(params[pk]) if params.has_key?(pk)
        end
        stages[stage] = JSON::Any.new(st) unless st.empty?
      end
      obj["stages"] = JSON::Any.new(stages) unless stages.empty?

      obj["assessed"] = JSON::Any.new(params["assessed"]) if params.has_key?("assessed")

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
