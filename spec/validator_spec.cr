require "./spec_helper"

describe Rigor::Validator do
  describe ".structural" do
    it "accepts a valid minimal document" do
      doc, _ = Rigor::Document.extract(File.read("spec/fixtures/minimal.md"))
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
      r.warnings.select { |w| w.includes?("implies") }.size.should eq(1)
    end

    it "errors when a surfaced check contradicts the level" do
      text = stamp_doc("rigor: engineered\nchecks:\n  comprehended: yes\n  quality_reviewed: yes\n  security_reviewed: no\nvouch: neutral")
      r = Rigor::Validator.validate(text)
      r.valid.should be_false
      r.errors.join.should contain("security_reviewed")
    end

    it "rejects list-form checks instead of silently passing (regression)" do
      # Before the fix, coerce_checks swallowed a non-mapping into {} and this
      # validated as true, hiding an engineered claim that contradicts
      # security_reviewed: no.
      text = stamp_doc("rigor: engineered\nchecks:\n  - security_reviewed: no\nvouch: yes")
      Rigor::Validator.validate(text).valid.should be_false
    end

    it "rejects a scalar checks value" do
      Rigor::Validator.validate(stamp_doc("rigor: engineered\nchecks: nope\nvouch: yes")).valid.should be_false
    end

    it "keeps a surfaced contradiction an error in strict mode too" do
      text = stamp_doc("rigor: engineered\nchecks:\n  comprehended: yes\n  quality_reviewed: yes\n  security_reviewed: no\nvouch: neutral")
      Rigor::Validator.validate(text, strict: true).valid.should be_false
    end

    it "warns on unattended AI maintenance with high rigor in BOTH modes" do
      text = stamp_doc("rigor: owned\nvouch: yes\nstages:\n  maintenance: {by: ai}")
      Rigor::Validator.validate(text).warnings.join.should contain("unattended")
      Rigor::Validator.validate(text, strict: true).warnings.join.should contain("unattended")
    end

    it "accepts actor values as done for review checks" do
      text = stamp_doc("rigor: engineered\nchecks:\n  comprehended: yes\n  quality_reviewed: ai\n  security_reviewed: human\n  tested: human-with-ai\nvouch: neutral")
      r = Rigor::Validator.validate(text)
      r.valid.should be_true
    end

    it "does not let an AI comprehension cross the line" do
      text = stamp_doc("rigor: comprehended\nchecks:\n  comprehended: ai\nvouch: neutral")
      r = Rigor::Validator.validate(text)
      r.valid.should be_false
      r.errors.join.should contain("comprehended")
    end

    it "accepts a stages block and rejects origin as an unknown field" do
      good = stamp_doc("rigor: skimmed\nvouch: neutral\nstages:\n  idea: {by: human, depth: deep}\n  plan: {by: human-with-ai, depth: considered}\n  implementation: {by: ai}\n  maintenance: {by: none}")
      Rigor::Validator.validate(good).valid.should be_true

      # origin is not part of the v0.2 vocabulary; the Stamp block never
      # migrates it, so it is rejected as an unknown field.
      bad = stamp_doc("rigor: skimmed\nvouch: neutral\norigin:\n  authored: ai-generated")
      Rigor::Validator.validate(bad).valid.should be_false
    end

    it "rejects depth on implementation and none outside maintenance" do
      Rigor::Validator.validate(stamp_doc("rigor: skimmed\nvouch: neutral\nstages:\n  implementation: {by: ai, depth: deep}")).valid.should be_false
      Rigor::Validator.validate(stamp_doc("rigor: skimmed\nvouch: neutral\nstages:\n  idea: {by: none}")).valid.should be_false
    end

    it "warns on unattended AI maintenance with high rigor" do
      text = stamp_doc("rigor: owned\nvouch: yes\nchecks:\n  comprehended: yes\n  quality_reviewed: yes\n  security_reviewed: yes\n  tested: yes\n  owned: yes\nstages:\n  maintenance: {by: ai}")
      Rigor::Validator.validate(text).warnings.join.should contain("unattended")
    end

    it "warns about a missing spec version" do
      text = stamp_doc("rigor: skimmed\nvouch: neutral")
      r = Rigor::Validator.validate(text)
      r.valid.should be_true
      r.warnings.join.should contain("spec version")
    end

    it "accepts the v0.2 fixtures without warnings" do
      r = Rigor::Validator.validate(File.read("spec/fixtures/engineered_v2.md"))
      r.valid.should be_true
      r.warnings.should be_empty
    end

    it "rejects a malformed assessed date and an unknown spec version" do
      Rigor::Validator.validate(stamp_doc("rigor: comprehended\nvouch: neutral\nassessed: July 2026")).valid.should be_false
      Rigor::Validator.validate(stamp_doc("rigor: comprehended\nvouch: neutral\nspec: \"9.9\"")).valid.should be_false
    end

    it "requires surfaced checks for levels above the line (show your working)" do
      r = Rigor::Validator.validate(stamp_doc("rigor: engineered\nvouch: yes"))
      r.valid.should be_false
      r.errors.join.should contain("show your working")
      # comprehended stays terse-friendly
      Rigor::Validator.validate(stamp_doc("rigor: comprehended\nvouch: neutral")).valid.should be_true
      # low levels stay terse-friendly
      Rigor::Validator.validate(stamp_doc("rigor: skimmed\nvouch: neutral")).valid.should be_true
    end

    it "errors when the summary block does not match the stamp" do
      text = File.read("spec/fixtures/minimal_v2.md").sub("I have read and understood", "I promise I read")
      r = Rigor::Validator.validate(text)
      r.valid.should be_false
      r.errors.join.should contain("summary")
    end

    it "accepts a matching summary block" do
      Rigor::Validator.validate(File.read("spec/fixtures/minimal_v2.md")).valid.should be_true
    end
  end
end
