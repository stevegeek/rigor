require "./spec_helper"

private def doc_for(path)
  d, _ = Rigor::Document.extract(File.read(path))
  d.not_nil!
end

describe Rigor::Embed do
  it "emits the README line block for a stamp" do
    d = doc_for("spec/fixtures/full_r3.md")
    Rigor::Embed.emit(d).should eq(Rigor::Summary.line_block(d))
  end

  it "agrees with Summary.line for a minimal stamp" do
    d = doc_for("spec/fixtures/minimal.md")
    Rigor::Embed.emit(d).should contain(%("#{Rigor::Summary.line(d)}"))
  end
end
