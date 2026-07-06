require "../spec_helper"

describe Rigor::Commands::Fmt do
  it "emits deterministic stamp yaml" do
    doc, _ = Rigor::Document.extract(File.read("spec/fixtures/engineered_v2.md"))
    yaml = Rigor::StampYAML.emit(doc.not_nil!)
    yaml.lines.first.should eq(%(spec: "0.2"))
    yaml.should contain("stages:")
    yaml.should contain("  idea: {by: human, depth: deep}")
    yaml.index("rigor:").not_nil!.should be < yaml.index("vouch:").not_nil!
  end

  it "regenerates a stale summary in place" do
    path = File.tempname("fmt", ".md")
    File.write(path, File.read("spec/fixtures/minimal_v2.md").sub("I have read and understood", "STALE"))
    Rigor::Commands::Fmt.run(path, IO::Memory.new).should eq(0)
    Rigor::Validator.validate(File.read(path)).valid.should be_true
    File.delete(path)
  end
end
