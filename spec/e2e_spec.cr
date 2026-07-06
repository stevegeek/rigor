require "./spec_helper"

describe "end to end via CLI.run" do
  it "validate → 0, embed → README line block" do
    Rigor::CLI.run(["validate", "spec/fixtures/full_r3.md"], IO::Memory.new).should eq(0)
    io = IO::Memory.new
    Rigor::CLI.run(["embed", "spec/fixtures/full_r3.md"], io)
    io.to_s.should contain(Rigor::Summary::LINE_MARKER_START)
    io.to_s.should contain(Rigor::Summary::LINE_MARKER_END)
    io.to_s.should contain("Paste into your README")
  end

  it "returns 2 on unknown command and 1 on invalid document" do
    Rigor::CLI.run(["frobnicate"], IO::Memory.new).should eq(2)
    bad = File.tempname("bad", ".md")
    File.write(bad, "no frontmatter")
    Rigor::CLI.run(["validate", bad], IO::Memory.new).should eq(1)
    File.delete(bad)
  end

  it "wires --readme through the CLI: drift → 1, missing README file → 2" do
    stamp = File.tempname("stamp", ".md")
    File.write(stamp, File.read("spec/fixtures/minimal.md"))
    readme = File.tempname("readme", ".md")
    File.write(readme, "# P\n\n<!-- rigor:line -->\n> \"stale\" — [RIGOR.md](RIGOR.md)\n<!-- /rigor:line -->\n")
    Rigor::CLI.run(["validate", stamp, "--readme", readme], IO::Memory.new).should eq(1)
    Rigor::CLI.run(["validate", stamp, "--readme", "/nonexistent-readme.md"], IO::Memory.new).should eq(2)
    File.delete(stamp)
    File.delete(readme)
  end

  it "the banner drops badge/serve and validate's usage line mentions --readme" do
    io = IO::Memory.new
    Rigor::CLI.run([] of String, io)
    io.to_s.should_not contain("badge")
    io.to_s.should_not contain("serve")

    io2 = IO::Memory.new
    Rigor::CLI.run(["validate"], io2)
    io2.to_s.should contain("--readme")
  end
end
