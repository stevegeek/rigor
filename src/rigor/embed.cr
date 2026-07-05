require "uri"
require "json"
require "./renderer"
require "./vocabulary"

module Rigor
  module Embed
    extend self

    PARAM_ORDER = %w[
      rigor vouch
      idea_by idea_depth plan_by plan_depth implementation_by maintenance_by
      assessed
      comprehended quality_reviewed security_reviewed tested owned
    ]

    def params_from(doc : JSON::Any) : Hash(String, String)
      p = {} of String => String
      p["rigor"] = doc["rigor"].as_s
      p["vouch"] = doc["vouch"].as_s
      if stages = doc["stages"]?.try(&.as_h?)
        Vocabulary::STAGE_KEYS.each do |k|
          next unless st = stages[k]?.try(&.as_h?)
          p["#{k}_by"] = st["by"].as_s if st.has_key?("by")
          p["#{k}_depth"] = st["depth"].as_s if st.has_key?("depth")
        end
      end
      p["assessed"] = doc["assessed"].as_s if doc["assessed"]?
      if checks = doc["checks"]?.try(&.as_h?)
        Vocabulary::CHECK_KEYS.each do |k|
          p[k] = checks[k].as_s if checks.has_key?(k)
        end
      end
      p
    end

    def canonical_query(params : Hash(String, String)) : String
      PARAM_ORDER.compact_map do |k|
        next unless params.has_key?(k)
        "#{k}=#{URI.encode_www_form(params[k])}"
      end.join("&")
    end

    def emit(doc : JSON::Any, base : String)
      query = canonical_query(params_from(doc))
      alt = Renderer.describe(doc)
      badge_url = "#{base}/badge.svg?#{query}"
      info_url = "#{base}/infobox.svg?#{query}"
      page_url = "#{base}/r?#{query}"
      {
        badge_url:        badge_url,
        infobox_url:      info_url,
        page_url:         page_url,
        alt:              alt,
        badge_markdown:   "[![#{alt}](#{badge_url})](#{page_url})",
        infobox_markdown: "[![#{alt}](#{info_url})](#{page_url})",
      }
    end
  end
end
