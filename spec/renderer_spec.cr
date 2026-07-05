require "./spec_helper"

private def doc_for(path)
  d, _, _ = Rigor::Document.extract(File.read(path))
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

    it "contains the level name, vouch, and the level color" do
      svg = Rigor::Renderer.badge(doc_for("spec/fixtures/full_r3.md"))
      svg.should contain("rigor engineered")
      svg.should contain("vouch yes")
      svg.should contain(Rigor::Vocabulary::LEVEL_COLOR["engineered"])
    end

    it "escapes angle brackets and quotes in the desc" do
      Rigor::Renderer.esc(%(a<b>"c&d)).should eq("a&lt;b&gt;&quot;c&amp;d")
    end
  end

  describe ".infobox" do
    it "includes the level definition and vouch" do
      svg = Rigor::Renderer.infobox(doc_for("spec/fixtures/minimal.md"))
      svg.should contain("Comprehended")
      svg.should contain("Vouch: neutral")
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
  end
end
