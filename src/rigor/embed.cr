require "json"
require "./summary"

module Rigor
  # The paste-ready README snippet. Thin on purpose: Summary owns the sentence
  # composition and marker logic; this module is the stable name the CLI
  # (`rigor embed`) calls, independent of how that text is assembled.
  module Embed
    extend self

    USAGE_HINT = "Paste into your README; rigor validate <file> --readme README.md will keep it honest."

    def emit(doc : JSON::Any) : String
      Summary.line_block(doc)
    end
  end
end
