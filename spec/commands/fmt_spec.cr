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

  it "inserts the summary block into a marker-less v0.2 file, and a second run is byte-identical" do
    path = File.tempname("fmt", ".md")
    File.write(path, "# T\n\n## Stamp\n\n```yaml\nrigor: comprehended\nvouch: neutral\n```\n")
    Rigor::Commands::Fmt.run(path, IO::Memory.new).should eq(0)
    once = File.read(path)
    once.should contain(Rigor::Summary::MARKER_START)
    Rigor::Validator.validate(once).valid.should be_true

    Rigor::Commands::Fmt.run(path, IO::Memory.new).should eq(0)
    File.read(path).should eq(once)
  ensure
    File.delete(path) if path
  end

  it "round-trips a notes value with escaped quotes through StampYAML.emit" do
    text = stamp_doc(%(rigor: skimmed\nvouch: neutral\nnotes: "text with \\"quotes\\""))
    doc, err = Rigor::Document.extract(text)
    err.should be_nil
    original_notes = doc.not_nil!["notes"].as_s

    yaml = Rigor::StampYAML.emit(doc.not_nil!)
    reparsed = YAML.parse(yaml)
    reparsed["notes"].as_s.should eq(original_notes)
  end
end
