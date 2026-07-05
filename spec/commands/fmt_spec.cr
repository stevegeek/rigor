require "../spec_helper"

describe Rigor::Commands::Fmt do
  it "emits deterministic stamp yaml" do
    doc, _, _ = Rigor::Document.extract(File.read("spec/fixtures/engineered_v2.md"))
    yaml = Rigor::StampYAML.emit(doc.not_nil!)
    yaml.lines.first.should eq(%(spec: "0.2"))
    yaml.should contain("stages:")
    yaml.should contain("  idea: {by: human, depth: deep}")
    yaml.index("rigor:").not_nil!.should be < yaml.index("vouch:").not_nil!
  end

  it "regenerates a stale summary in place" do
    path = File.tempname("fmt", ".md")
    File.write(path, File.read("spec/fixtures/minimal_v2.md").sub("I have read and understood", "STALE"))
    Rigor::Commands::Fmt.run(path, false, IO::Memory.new).should eq(0)
    Rigor::Validator.validate(File.read(path)).valid.should be_true
    File.delete(path)
  end

  it "refuses a legacy file without --migrate, converts it with" do
    path = File.tempname("legacy", ".md")
    File.write(path, File.read("spec/fixtures/legacy_v01.md"))
    Rigor::Commands::Fmt.run(path, false, IO::Memory.new).should eq(1)
    Rigor::Commands::Fmt.run(path, true, IO::Memory.new).should eq(0)
    text = File.read(path)
    text.should contain("## Stamp")
    text.should contain("implementation: {by: ai}")
    text.should contain(Rigor::Summary::MARKER_START)
    Rigor::Validator.validate(text).valid.should be_true
    File.delete(path)
  end

  it "migrates a v0.1 file but flags it when it is not valid under v0.2 rules" do
    path = File.tempname("legacy_invalid", ".md")
    File.write(path, "---\nrigor: R3\nchecks:\n  security_reviewed: yes\nvouch: neutral\n---\n# body\n")
    io = IO::Memory.new
    Rigor::Commands::Fmt.run(path, true, io).should eq(1)
    text = File.read(path)
    text.should contain("## Stamp")
    text.should contain("rigor: engineered")
    io.to_s.should contain("show your working")
    File.delete(path)
  end
end
