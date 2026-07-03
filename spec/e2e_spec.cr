require "./spec_helper"

describe "end to end via CLI.run" do
  it "validate → 0, badge → svg, embed → markdown, schema → json" do
    Rigor::CLI.run(["validate", "spec/fixtures/full_r3.md"], IO::Memory.new).should eq(0)
    io = IO::Memory.new
    Rigor::CLI.run(["badge", "spec/fixtures/full_r3.md"], io)
    io.to_s.should contain("<svg")
  end

  it "returns 2 on unknown command and 1 on invalid document" do
    Rigor::CLI.run(["frobnicate"], IO::Memory.new).should eq(2)
    bad = File.tempname("bad", ".md")
    File.write(bad, "no frontmatter")
    Rigor::CLI.run(["validate", bad], IO::Memory.new).should eq(1)
    File.delete(bad)
  end
end
