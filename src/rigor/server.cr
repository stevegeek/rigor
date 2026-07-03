require "http/server"
require "uri"
require "digest/sha1"
require "./renderer"

module Rigor
  class Server
    def initialize(@base : String)
    end

    def handle(context : HTTP::Server::Context)
      request = context.request
      response = context.response
      params = query_hash(request.query)

      case request.path
      when "/badge.svg"   then render_svg(response, params, infobox: false)
      when "/infobox.svg" then render_svg(response, params, infobox: true)
      when "/r"           then render_page(response, params)
      else
        response.status_code = 404
        response.content_type = "text/plain"
        response.print "not found"
      end
    end

    private def render_svg(response, params, infobox : Bool)
      result = Renderer.decode_params(params)
      svg =
        if result.valid && (doc = result.doc)
          infobox ? Renderer.infobox(doc) : Renderer.badge(doc)
        else
          Renderer.invalid_badge(result.errors)
        end
      response.status_code = result.valid ? 200 : 400
      response.content_type = "image/svg+xml"
      if result.valid
        response.headers["Cache-Control"] = "public, max-age=31536000, immutable"
        response.headers["ETag"] = %("#{Digest::SHA1.hexdigest(svg)}")
      end
      response.print svg
    end

    private def render_page(response, params)
      result = Renderer.decode_params(params)
      response.content_type = "text/html; charset=utf-8"
      if result.valid && (doc = result.doc)
        response.headers["Cache-Control"] = "public, max-age=31536000, immutable"
        response.print <<-HTML
        <!doctype html><meta charset="utf-8"><title>Rigor disclosure</title>
        <body style="font-family:system-ui;max-width:40rem;margin:3rem auto">
        #{Renderer.infobox(doc)}
        <p>#{Renderer.esc(Renderer.describe(doc))}</p>
        </body>
        HTML
      else
        response.status_code = 400
        response.print "<!doctype html><p>Invalid parameters: #{Renderer.esc(result.errors.join("; "))}</p>"
      end
    end

    private def query_hash(query : String?) : Hash(String, String)
      h = {} of String => String
      return h unless query
      query.split('&').each do |pair|
        next if pair.empty?
        k, _, v = pair.partition('=')
        h[k] = URI.decode_www_form(v)
      end
      h
    end
  end
end
