require "../validator"

module Rigor::Commands::Schema
  extend self

  def run(io : IO) : Int32
    io.puts Rigor::Validator::SCHEMA_JSON
    0
  end
end
