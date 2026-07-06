require "./spec_helper"

describe Rigor::Document do
  describe ".normalize_rigor" do
    it "passes canonical names through" do
      Rigor::Document.normalize_rigor("engineered").should eq("engineered")
    end
    it "is case-insensitive on names and trims whitespace" do
      Rigor::Document.normalize_rigor("  Owned ").should eq("owned")
    end
    it "passes unknown values through unchanged" do
      Rigor::Document.normalize_rigor("bogus").should eq("bogus")
    end
  end

  describe ".extract" do
    it "errors when there is no stamp" do
      doc, err = Rigor::Document.extract("no frontmatter here")
      doc.should be_nil
      err.not_nil!.should contain("No stamp found")
    end

    it "coerces YAML yes/no booleans back to strings and normalizes rigor" do
      text = File.read("spec/fixtures/full_r3.md")
      doc, err = Rigor::Document.extract(text)
      err.should be_nil
      d = doc.not_nil!
      d["rigor"].as_s.should eq("engineered")
      d["checks"]["comprehended"].as_s.should eq("yes")
      d["checks"]["tested"].as_s.should eq("not-applicable")
      d["vouch"].as_s.should eq("yes")
    end

    it "errors on invalid YAML" do
      doc, err = Rigor::Document.extract(stamp_doc(" rigor: : :"))
      doc.should be_nil
      err.not_nil!.should contain("YAML")
    end

    it "rejects YAML anchors/aliases (billion-laughs vector)" do
      text = stamp_doc("rigor: comprehended\nvouch: neutral\na: &a [x, x]\nb: [*a, *a]")
      doc, err = Rigor::Document.extract(text)
      doc.should be_nil
      err.not_nil!.should contain("anchors/aliases")
    end

    it "rejects an oversized stamp" do
      big = stamp_doc("rigor: comprehended\nvouch: neutral\n" + ("# pad\n" * 20000))
      doc, err = Rigor::Document.extract(big)
      doc.should be_nil
      err.not_nil!.should contain("too large")
    end

    it "rejects a v0.2 Stamp block whose yaml exceeds Document::MAX_STAMP_BYTES" do
      big = stamp_doc("rigor: comprehended\nvouch: neutral\n# " + ("a" * Rigor::Document::MAX_STAMP_BYTES))
      doc, err = Rigor::Document.extract(big)
      doc.should be_nil
      err.not_nil!.should contain("too large")
    end

    it "does not crash on pathological whitespace with no closing fence" do
      text = "## Stamp\n\n```yaml\n" + ("\n \t" * 20000) + "rigor: comprehended\n"
      doc, err = Rigor::Document.extract(text)
      doc.should be_nil
      err.not_nil!.should contain("No stamp found")
    end

    it "preserves a non-mapping checks value so the schema can reject it" do
      # list-form checks (a very common YAML mistake) must not be swallowed
      doc, err = Rigor::Document.extract(stamp_doc("rigor: engineered\nchecks:\n  - security_reviewed: no\nvouch: yes"))
      err.should be_nil
      doc.not_nil!["checks"].as_a?.should_not be_nil
    end
  end

  describe ".extract v0.2 layout" do
    it "parses the trailing Stamp block" do
      doc, err = Rigor::Document.extract(File.read("spec/fixtures/minimal_v2.md"))
      err.should be_nil
      doc.not_nil!["rigor"].as_s.should eq("comprehended")
      doc.not_nil!["spec"].as_s.should eq("0.3")
    end

    it "coerces a bare spec: 0.3 scalar to a string" do
      text = stamp_doc("spec: 0.3\nrigor: comprehended\nvouch: neutral")
      doc, _ = Rigor::Document.extract(text)
      doc.not_nil!["spec"].as_s.should eq("0.3")
    end

    it "uses the LAST Stamp heading's yaml block" do
      text = File.read("spec/fixtures/minimal_v2.md") +
             "\n## Stamp\n\n```yaml\nrigor: owned\nvouch: yes\n```\n"
      doc, _ = Rigor::Document.extract(text)
      doc.not_nil!["rigor"].as_s.should eq("owned")
    end

    it "errors on a frontmatter-only file, mentioning Stamp" do
      text = "---\nrigor: comprehended\nvouch: neutral\n---\n# body\n"
      doc, err = Rigor::Document.extract(text)
      doc.should be_nil
      err.not_nil!.should contain("Stamp")
    end

    it "errors clearly when no stamp is present" do
      _, err = Rigor::Document.extract("just prose")
      err.not_nil!.should contain("Stamp")
    end

    it "coerces an unquoted day-precision assessed date to YYYY-MM-DD" do
      text = stamp_doc("rigor: comprehended\nvouch: neutral\nassessed: 2026-07-15")
      doc, err = Rigor::Document.extract(text)
      err.should be_nil
      doc.not_nil!["assessed"].as_s.should eq("2026-07-15")
    end
  end
end
