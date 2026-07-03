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

    it "warns on ai-auto maintenance with high rigor in BOTH modes" do
      text = "---\nrigor: R4\nvouch: yes\norigin:\n  maintenance: ai-auto\n---\n"
      Rigor::Validator.validate(text).warnings.join.should contain("ai-auto")
      Rigor::Validator.validate(text, strict: true).warnings.join.should contain("ai-auto")
    end
  end
end
