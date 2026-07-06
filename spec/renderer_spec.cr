require "./spec_helper"

private def doc_for(path)
  d, _ = Rigor::Document.extract(File.read(path))
  d.not_nil!
end

describe Rigor::Renderer do
  describe ".describe" do
    it "states the author's claimed level as a first-person sentence" do
      Rigor::Renderer.describe(doc_for("spec/fixtures/full_r3.md"))
        .should contain("I understand this code; it was deliberately reviewed for quality and for security")
    end

    it "does not assert 'tested' when tested is not-applicable" do
      text = Rigor::Renderer.describe(doc_for("spec/fixtures/full_r3.md"))
      # tested is not-applicable in this fixture; it must not appear as a done check
      text.should_not contain("tested")
    end

    it "lists only surfaced yes-checks" do
      doc = JSON.parse(%({"rigor":"owned","vouch":"yes","checks":{"security_reviewed":"yes"}}))
      text = Rigor::Renderer.describe(doc)
      text.should contain("reviewed for security")
      text.should_not contain("comprehended")
    end

    it "states the vouch and stage story" do
      text = Rigor::Renderer.describe(doc_for("spec/fixtures/full_r3.md"))
      text.should contain("I recommend this for use; I put my name behind it.")
      text.should contain("A human drives changes today.")
    end
  end

  describe ".badge" do
    it "is deterministic for identical input" do
      d = doc_for("spec/fixtures/full_r3.md")
      Rigor::Renderer.badge(d).should eq(Rigor::Renderer.badge(d))
    end

    it "escapes angle brackets and quotes in the desc" do
      Rigor::Renderer.esc(%(a<b>"c&d)).should eq("a&lt;b&gt;&quot;c&amp;d")
    end

    it "renders plain-language badge text with matching title and aria-label" do
      doc, _ = Rigor::Document.extract(File.read("spec/fixtures/minimal_v2.md"))
      svg = Rigor::Renderer.badge(doc.not_nil!)
      svg.should contain(">comprehended<")
      svg.should contain(">no vouch<")
      svg.should contain(%(aria-label="comprehended | no vouch"))
      svg.should contain("<title>comprehended | no vouch</title>")
      svg.should contain("I make no recommendation")
    end

    it "qualifies a below-the-line badge when review was AI-only" do
      text = stamp_doc("rigor: skimmed\nvouch: neutral\nchecks:\n  security_reviewed: ai")
      doc, _ = Rigor::Document.extract(text)
      Rigor::Renderer.badge(doc.not_nil!).should contain("skimmed · AI-reviewed")
    end

    it "does not qualify a below-the-line badge when the review was human-with-ai, not AI-only" do
      text = stamp_doc("rigor: skimmed\nvouch: neutral\nchecks:\n  quality_reviewed: human-with-ai")
      doc, _ = Rigor::Document.extract(text)
      Rigor::Renderer.badge(doc.not_nil!).should_not contain("AI-reviewed")
    end

    it "uses neutral slate for honest low stamps, not warning amber" do
      text = stamp_doc("rigor: skimmed\nvouch: neutral")
      doc, _ = Rigor::Document.extract(text)
      svg = Rigor::Renderer.badge(doc.not_nil!)
      svg.should contain("#64748b")
      svg.should_not contain("#c2410c")
    end
  end

  describe ".infobox" do
    it "includes the level definition and vouch" do
      svg = Rigor::Renderer.infobox(doc_for("spec/fixtures/minimal.md"))
      svg.should contain("Comprehended")
      svg.should contain("Vouch: no vouch")
    end

    it "agrees with the visible vouch label in its <title>" do
      svg = Rigor::Renderer.infobox(doc_for("spec/fixtures/minimal.md"))
      svg.should contain("<title>Rigor comprehended, no vouch</title>")
    end
  end

  describe ".invalid_badge" do
    it "renders a grey invalid pill mentioning the error" do
      svg = Rigor::Renderer.invalid_badge(["rigor is required"])
      svg.should contain("rigor: invalid")
      svg.should contain("rigor is required")
    end
  end

  describe ".decode_params" do
    it "normalizes a rigor name in params and validates" do
      res = Rigor::Renderer.decode_params({"rigor" => "engineered", "vouch" => "yes",
                                           "comprehended" => "yes", "quality_reviewed" => "yes",
                                           "security_reviewed" => "yes", "tested" => "yes"})
      res.valid.should be_true
      res.doc.not_nil!["rigor"].as_s.should eq("engineered")
    end

    it "reports invalid params" do
      res = Rigor::Renderer.decode_params({"rigor" => "R9", "vouch" => "yes"})
      res.valid.should be_false
    end

    it "carries assessed through so the described page matches the embed alt text" do
      res = Rigor::Renderer.decode_params({"rigor" => "comprehended", "vouch" => "neutral", "assessed" => "2026-07"})
      Rigor::Renderer.describe(res.doc.not_nil!).should contain("This assessment is as of 2026-07.")
    end
  end
end
