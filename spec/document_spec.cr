require "./spec_helper"

describe Rigor::Document do
  describe ".normalize_rigor" do
    it "passes canonical codes through" do
      Rigor::Document.normalize_rigor("R3").should eq("R3")
    end
    it "maps a name to its code" do
      Rigor::Document.normalize_rigor("engineered").should eq("R3")
    end
    it "takes the leading code from the combined form" do
      Rigor::Document.normalize_rigor("R3 engineered").should eq("R3")
      Rigor::Document.normalize_rigor("R3 Engineered").should eq("R3")
    end
    it "is case-insensitive on names and trims whitespace" do
      Rigor::Document.normalize_rigor("  Owned ").should eq("R4")
    end
    it "passes unknown values through unchanged" do
      Rigor::Document.normalize_rigor("bogus").should eq("bogus")
    end
  end

  describe ".extract" do
    it "errors when there is no frontmatter" do
      doc, err = Rigor::Document.extract("no frontmatter here")
      doc.should be_nil
      err.not_nil!.should contain("No frontmatter")
    end

    it "coerces YAML yes/no booleans back to strings and normalizes rigor" do
      text = File.read("spec/fixtures/full_r3.md")
      doc, err = Rigor::Document.extract(text)
      err.should be_nil
      d = doc.not_nil!
      d["rigor"].as_s.should eq("R3")
      d["checks"]["comprehended"].as_s.should eq("yes")
      d["checks"]["tested"].as_s.should eq("not-applicable")
      d["vouch"].as_s.should eq("yes")
    end

    it "errors on invalid YAML" do
      doc, err = Rigor::Document.extract("---\n rigor: : :\n---\n")
      doc.should be_nil
      err.not_nil!.should contain("YAML")
    end

    it "rejects YAML anchors/aliases (billion-laughs vector)" do
      text = "---\nrigor: R2\nvouch: neutral\na: &a [x, x]\nb: [*a, *a]\n---\n"
      doc, err = Rigor::Document.extract(text)
      doc.should be_nil
      err.not_nil!.should contain("anchors/aliases")
    end

    it "rejects oversized frontmatter" do
      big = "---\nrigor: R2\nvouch: neutral\n" + ("# pad\n" * 20000) + "---\n"
      doc, err = Rigor::Document.extract(big)
      doc.should be_nil
      err.not_nil!.should contain("too large")
    end

    it "does not crash on pathological whitespace with no closing fence" do
      text = "---\n" + ("\n \t" * 20000) + "rigor: R2\n"
      doc, err = Rigor::Document.extract(text)
      doc.should be_nil
      err.not_nil!.should contain("No frontmatter")
    end

    it "preserves a non-mapping checks value so the schema can reject it" do
      # list-form checks (a very common YAML mistake) must not be swallowed
      doc, err = Rigor::Document.extract("---\nrigor: R3\nchecks:\n  - security_reviewed: no\nvouch: yes\n---\n")
      err.should be_nil
      doc.not_nil!["checks"].as_a?.should_not be_nil
    end
  end
end
