require "../spec_helper"

describe Rigor::Commands::Schema do
  it "prints valid JSON that is the canonical schema" do
    io = IO::Memory.new
    Rigor::Commands::Schema.run(io).should eq(0)
    parsed = JSON.parse(io.to_s)
    parsed["required"].as_a.map(&.as_s).should eq(["rigor", "vouch"])
  end
end
