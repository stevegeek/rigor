require "yaml"
require "json"
require "./vocabulary"

module Rigor
  module Document
    extend self

    # Fences may carry trailing spaces/tabs and CRLF, but NOT arbitrary
    # whitespace: `\s*` overlaps the `\n` and backtracks catastrophically on
    # whitespace-heavy input with no closing fence. `[ \t]*\r?\n` cannot.
    FRONTMATTER = /\A---[ \t]*\r?\n(.*?)\r?\n---[ \t]*(?:\r?\n|\z)/m

    # The stamp is spec'd as shallow and hand-written; a real one is well under
    # 1 KB. Cap the frontmatter so a hostile file cannot force a huge parse.
    MAX_FRONTMATTER_BYTES = 64 * 1024

    # Normalize any accepted alias — v0.2 name, R-code, v0.1 name, or the
    # combined "R3 engineered" form — to the canonical v0.2 name. Unknown
    # values pass through so the schema reports them.
    def normalize_rigor(value : String) : String
      token = value.strip
      resolved = resolve_level(token)
      return resolved if resolved
      token.split(/\s+/).each do |part|
        if r = resolve_level(part)
          return r
        end
      end
      value
    end

    private def resolve_level(token : String) : String?
      down = token.downcase
      return down if Vocabulary::LEVELS.includes?(down)
      Vocabulary::CODE_TO_NAME[token]? || Vocabulary::CODE_TO_NAME[token.upcase]? ||
        Vocabulary::V01_NAMES[down]?
    end

    def extract(text : String) : {JSON::Any?, String?}
      m =
        begin
          FRONTMATTER.match(text)
        rescue Regex::Error
          # Pathological input that trips the PCRE match limit is treated as
          # "no frontmatter" rather than crashing the process.
          nil
        end
      unless m
        return {nil, "No frontmatter block found. Expected a '---' fenced YAML block at the top of the file."}
      end

      fm = m[1]
      if fm.bytesize > MAX_FRONTMATTER_BYTES
        return {nil, "Frontmatter is too large (#{fm.bytesize} bytes; limit is #{MAX_FRONTMATTER_BYTES})."}
      end

      # YAML anchors/aliases are never needed in a shallow stamp and enable a
      # "billion laughs" expansion that detonates during parse. Reject them.
      if contains_alias?(fm)
        return {nil, "Frontmatter uses YAML anchors/aliases, which are not allowed."}
      end

      yaml = begin
        YAML.parse(fm)
      rescue ex : YAML::ParseException
        return {nil, "Frontmatter is not valid YAML: #{ex.message}"}
      end

      raw = yaml.raw
      unless raw.is_a?(Hash)
        return {nil, "Frontmatter parsed but is not a mapping of fields."}
      end

      {coerce_top(yaml), nil}
    end

    # Walk YAML events without materializing the tree; true if any alias node
    # appears (which is what expands a bomb).
    private def contains_alias?(str : String) : Bool
      parser = YAML::PullParser.new(str)
      loop do
        return true if parser.kind.alias?
        break if parser.kind.stream_end?
        parser.read_next
      end
      false
    rescue YAML::ParseException
      # Malformed YAML: let the real parse below report it.
      false
    end

    # Convert the parsed YAML mapping into a normalized JSON::Any document:
    # rigor -> canonical code; vouch and checks -> Norway-coerced strings.
    private def coerce_top(yaml : YAML::Any) : JSON::Any
      obj = {} of String => JSON::Any
      yaml.as_h.each do |k, v|
        key = k.as_s
        obj[key] =
          case key
          when "rigor"
            JSON::Any.new(normalize_rigor(yaml_scalar_to_s(v)))
          when "vouch"
            coerce_yes_no(v)
          when "checks"
            coerce_checks(v)
          else
            to_json_any(v)
          end
      end
      JSON::Any.new(obj)
    end

    # A mapping is Norway-coerced per key. A non-mapping (list, scalar) is
    # passed through with its real type PRESERVED, so the schema's
    # `checks: {type: object}` rejects it instead of it being silently dropped.
    private def coerce_checks(v : YAML::Any) : JSON::Any
      raw = v.raw
      if raw.is_a?(Hash)
        h = {} of String => JSON::Any
        v.as_h.each { |ck, cv| h[ck.as_s] = coerce_yes_no(cv) }
        return JSON::Any.new(h)
      end
      to_json_any(v)
    end

    # YAML parses bare yes/no into Bool (Norway problem). Authors write
    # `comprehended: yes`, so map booleans back to the intended strings. A
    # non-boolean scalar (e.g. "not-applicable") is returned unchanged.
    private def coerce_yes_no(v : YAML::Any) : JSON::Any
      case v.raw
      when true  then JSON::Any.new("yes")
      when false then JSON::Any.new("no")
      else            to_json_any(v)
      end
    end

    private def yaml_scalar_to_s(v : YAML::Any) : String
      raw = v.raw
      raw.is_a?(String) ? raw : raw.to_s
    end

    # Faithful YAML::Any -> JSON::Any for fields we do not special-case.
    private def to_json_any(v : YAML::Any) : JSON::Any
      case raw = v.raw
      when Nil     then JSON::Any.new(nil)
      when Bool    then JSON::Any.new(raw)
      when Int64   then JSON::Any.new(raw)
      when Float64 then JSON::Any.new(raw)
      when String  then JSON::Any.new(raw)
      when Array
        JSON::Any.new(v.as_a.map { |e| to_json_any(e) })
      when Hash
        h = {} of String => JSON::Any
        v.as_h.each { |hk, hv| h[hk.as_s] = to_json_any(hv) }
        JSON::Any.new(h)
      else
        JSON::Any.new(raw.to_s)
      end
    end
  end
end
