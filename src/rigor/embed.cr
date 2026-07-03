require "uri"
require "json"
require "./renderer"
require "./vocabulary"

module Rigor
  module Embed
    extend self

    PARAM_ORDER = %w[
      rigor vouch authored maintenance
      comprehended quality_reviewed security_reviewed tested owned
    ]

    def params_from(doc : JSON::Any) : Hash(String, String)
      p = {} of String => String
      p["rigor"] = doc["rigor"].as_s
      p["vouch"] = doc["vouch"].as_s
      if origin = doc["origin"]?.try(&.as_h?)
        p["authored"] = origin["authored"].as_s if origin.has_key?("authored")
        p["maintenance"] = origin["maintenance"].as_s if origin.has_key?("maintenance")
      end
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
