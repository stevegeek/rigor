require "./spec_helper"

private def doc_for(path)
  d, _, _ = Rigor::Document.extract(File.read(path))
  d.not_nil!
end

describe Rigor::Embed do
  it "emits params in canonical order" do
    q = Rigor::Embed.canonical_query(Rigor::Embed.params_from(doc_for("spec/fixtures/full_r3.md")))
    q.should start_with("rigor=engineered&vouch=yes&idea_by=human&idea_depth=deep&implementation_by=human-with-ai&maintenance_by=human")
  end

  it "alt text equals the renderer description" do
    d = doc_for("spec/fixtures/full_r3.md")
    Rigor::Embed.emit(d, "https://example.dev")[:alt].should eq(Rigor::Renderer.describe(d))
  end

  it "builds a markdown badge that links to the page" do
    md = Rigor::Embed.emit(doc_for("spec/fixtures/minimal.md"), "https://example.dev")[:badge_markdown]
    md.should contain("https://example.dev/badge.svg?")
    md.should contain("](https://example.dev/r?")
  end
end
