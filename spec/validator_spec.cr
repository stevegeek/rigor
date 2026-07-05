require "./spec_helper"

describe Rigor::Validator do
  describe ".structural" do
    it "accepts a valid minimal document" do
      doc, _, _ = Rigor::Document.extract(File.read("spec/fixtures/minimal.md"))
      Rigor::Validator.structural(doc.not_nil!).should be_empty
    end

    it "rejects an unknown field and a bad vouch value" do
      doc = JSON.parse(%({"rigor":"R2","vouch":"maybe","bogus":1}))
      errs = Rigor::Validator.structural(doc)
      errs.join("\n").should contain("/vouch")
      errs.join("\n").should contain("/bogus")
    end
  end

  describe ".validate" do
    it "accepts the full R3 example" do
      r = Rigor::Validator.validate(File.read("spec/fixtures/full_r3.md"))
      r.valid.should be_true
      r.errors.should be_empty
    end

    it "accepts the R4-partial example with NO warnings in non-strict mode" do
      r = Rigor::Validator.validate(File.read("spec/fixtures/r4_partial.md"))
      r.valid.should be_true
      r.warnings.select { |w| w.includes?("implies") }.should be_empty
    end

    it "warns about unsurfaced implied checks in strict mode" do
      r = Rigor::Validator.validate(File.read("spec/fixtures/r4_partial.md"), strict: true)
      r.valid.should be_true
      r.warnings.select { |w| w.includes?("implies") }.size.should eq(4)
    end

    it "errors when a surfaced check contradicts the level" do
      text = "---\nrigor: R3\nchecks:\n  comprehended: yes\n  quality_reviewed: yes\n  security_reviewed: no\nvouch: neutral\n---\n"
      r = Rigor::Validator.validate(text)
      r.valid.should be_false
      r.errors.join.should contain("security_reviewed")
    end

    it "rejects list-form checks instead of silently passing (regression)" do
      # Before the fix, coerce_checks swallowed a non-mapping into {} and this
      # validated as true, hiding an R3 claim that contradicts security_reviewed: no.
      text = "---\nrigor: R3\nchecks:\n  - security_reviewed: no\nvouch: yes\n---\n"
      Rigor::Validator.validate(text).valid.should be_false
    end

    it "rejects a scalar checks value" do
      Rigor::Validator.validate("---\nrigor: R3\nchecks: nope\nvouch: yes\n---\n").valid.should be_false
    end

    it "keeps a surfaced contradiction an error in strict mode too" do
      text = "---\nrigor: R3\nchecks:\n  comprehended: yes\n  quality_reviewed: yes\n  security_reviewed: no\nvouch: neutral\n---\n"
      Rigor::Validator.validate(text, strict: true).valid.should be_false
    end

    it "warns on unattended AI maintenance with high rigor in BOTH modes" do
      text = "---\nrigor: R4\nvouch: yes\nstages:\n  maintenance: {by: ai}\n---\n"
      Rigor::Validator.validate(text).warnings.join.should contain("unattended")
      Rigor::Validator.validate(text, strict: true).warnings.join.should contain("unattended")
    end

    it "accepts actor values as done for review checks" do
      text = "---\nrigor: engineered\nchecks:\n  comprehended: yes\n  quality_reviewed: ai\n  security_reviewed: human\n  tested: human-with-ai\nvouch: neutral\n---\n"
      r = Rigor::Validator.validate(text)
      r.valid.should be_true
    end

    it "does not let an AI comprehension cross the line" do
      text = "---\nrigor: comprehended\nchecks:\n  comprehended: ai\nvouch: neutral\n---\n"
      r = Rigor::Validator.validate(text)
      r.valid.should be_false
      r.errors.join.should contain("comprehended")
    end

    it "accepts a stages block and rejects origin as unknown in a v0.2 stamp" do
      good = "---\nrigor: skimmed\nvouch: neutral\nstages:\n  idea: {by: human, depth: deep}\n  plan: {by: human-with-ai, depth: considered}\n  implementation: {by: ai}\n  maintenance: {by: none}\n---\n"
      Rigor::Validator.validate(good).valid.should be_true

      # Under legacy v0.1 frontmatter, origin is a migrated input alias (see
      # document_spec's legacy test), so it can no longer be used to prove
      # origin is rejected. A v0.2 Stamp block does NOT migrate: origin there
      # is genuinely unknown to the schema.
      bad = "# T\n\n## Stamp\n\n```yaml\nrigor: skimmed\nvouch: neutral\norigin:\n  authored: ai-generated\n```\n"
      Rigor::Validator.validate(bad).valid.should be_false
    end

    it "rejects depth on implementation and none outside maintenance" do
      Rigor::Validator.validate("---\nrigor: skimmed\nvouch: neutral\nstages:\n  implementation: {by: ai, depth: deep}\n---\n").valid.should be_false
      Rigor::Validator.validate("---\nrigor: skimmed\nvouch: neutral\nstages:\n  idea: {by: none}\n---\n").valid.should be_false
    end

    it "warns on unattended AI maintenance with high rigor" do
      text = "---\nrigor: owned\nvouch: yes\nchecks:\n  comprehended: yes\n  quality_reviewed: yes\n  security_reviewed: yes\n  tested: yes\n  owned: yes\nstages:\n  maintenance: {by: ai}\n---\n"
      Rigor::Validator.validate(text).warnings.join.should contain("unattended")
    end

    it "warns about legacy format and missing spec version" do
      r = Rigor::Validator.validate(File.read("spec/fixtures/legacy_v01.md"))
      r.valid.should be_true
      r.warnings.join.should contain("v0.1")
      r.warnings.join.should contain("spec version")
    end

    it "accepts the v0.2 fixtures without warnings about format" do
      r = Rigor::Validator.validate(File.read("spec/fixtures/engineered_v2.md"))
      r.valid.should be_true
      r.warnings.join.should_not contain("v0.1")
    end

    it "rejects a malformed assessed date and an unknown spec version" do
      Rigor::Validator.validate("---\nrigor: comprehended\nvouch: neutral\nassessed: July 2026\n---\n").valid.should be_false
      Rigor::Validator.validate("---\nrigor: comprehended\nvouch: neutral\nspec: \"9.9\"\n---\n").valid.should be_false
    end
  end
end
