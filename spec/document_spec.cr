require "./spec_helper"

describe Rigor::Document do
  describe ".normalize_rigor" do
    it "passes canonical names through" do
      Rigor::Document.normalize_rigor("engineered").should eq("engineered")
    end
    it "maps a code to its name" do
      Rigor::Document.normalize_rigor("R3").should eq("engineered")
      Rigor::Document.normalize_rigor("R1").should eq("skimmed")
    end
    it "maps v0.1 names to v0.2 names" do
      Rigor::Document.normalize_rigor("surface").should eq("skimmed")
      Rigor::Document.normalize_rigor("none").should eq("unexamined")
    end
    it "takes the resolvable part of the combined form" do
      Rigor::Document.normalize_rigor("R3 engineered").should eq("engineered")
      Rigor::Document.normalize_rigor("R3 Engineered").should eq("engineered")
    end
    it "is case-insensitive on names and trims whitespace" do
      Rigor::Document.normalize_rigor("  Owned ").should eq("owned")
    end
    it "passes unknown values through unchanged" do
      Rigor::Document.normalize_rigor("bogus").should eq("bogus")
    end
  end

  describe ".extract" do
    it "errors when there is no frontmatter" do
      doc, err, _legacy = Rigor::Document.extract("no frontmatter here")
      doc.should be_nil
      err.not_nil!.should contain("No stamp found")
    end

    it "coerces YAML yes/no booleans back to strings and normalizes rigor" do
      text = File.read("spec/fixtures/full_r3.md")
      doc, err, _legacy = Rigor::Document.extract(text)
      err.should be_nil
      d = doc.not_nil!
      d["rigor"].as_s.should eq("engineered")
      d["checks"]["comprehended"].as_s.should eq("yes")
      d["checks"]["tested"].as_s.should eq("not-applicable")
      d["vouch"].as_s.should eq("yes")
    end

    it "errors on invalid YAML" do
      doc, err, _legacy = Rigor::Document.extract("---\n rigor: : :\n---\n")
      doc.should be_nil
      err.not_nil!.should contain("YAML")
    end

    it "rejects YAML anchors/aliases (billion-laughs vector)" do
      text = "---\nrigor: R2\nvouch: neutral\na: &a [x, x]\nb: [*a, *a]\n---\n"
      doc, err, _legacy = Rigor::Document.extract(text)
      doc.should be_nil
      err.not_nil!.should contain("anchors/aliases")
    end

    it "rejects oversized frontmatter" do
      big = "---\nrigor: R2\nvouch: neutral\n" + ("# pad\n" * 20000) + "---\n"
      doc, err, _legacy = Rigor::Document.extract(big)
      doc.should be_nil
      err.not_nil!.should contain("too large")
    end

    it "does not crash on pathological whitespace with no closing fence" do
      text = "---\n" + ("\n \t" * 20000) + "rigor: R2\n"
      doc, err, _legacy = Rigor::Document.extract(text)
      doc.should be_nil
      err.not_nil!.should contain("No stamp found")
    end

    it "preserves a non-mapping checks value so the schema can reject it" do
      # list-form checks (a very common YAML mistake) must not be swallowed
      doc, err, _legacy = Rigor::Document.extract("---\nrigor: R3\nchecks:\n  - security_reviewed: no\nvouch: yes\n---\n")
      err.should be_nil
      doc.not_nil!["checks"].as_a?.should_not be_nil
    end
  end

  describe ".extract v0.2 layout" do
    it "parses the trailing Stamp block and is not legacy" do
      doc, err, legacy = Rigor::Document.extract(File.read("spec/fixtures/minimal_v2.md"))
      err.should be_nil
      legacy.should be_false
      doc.not_nil!["rigor"].as_s.should eq("comprehended")
      doc.not_nil!["spec"].as_s.should eq("0.2")
    end

    it "coerces a bare spec: 0.2 scalar to a string" do
      text = "---\nspec: 0.2\nrigor: comprehended\nvouch: neutral\n---\n"
      doc, _, _ = Rigor::Document.extract(text)
      doc.not_nil!["spec"].as_s.should eq("0.2")
    end

    it "uses the LAST Stamp heading's yaml block" do
      text = File.read("spec/fixtures/minimal_v2.md") +
             "\n## Stamp\n\n```yaml\nrigor: owned\nvouch: yes\n```\n"
      doc, _, _ = Rigor::Document.extract(text)
      doc.not_nil!["rigor"].as_s.should eq("owned")
    end

    it "falls back to v0.1 frontmatter, flags legacy, migrates origin to stages" do
      doc, err, legacy = Rigor::Document.extract(File.read("spec/fixtures/legacy_v01.md"))
      err.should be_nil
      legacy.should be_true
      d = doc.not_nil!
      d["rigor"].as_s.should eq("skimmed")
      d["stages"]["implementation"]["by"].as_s.should eq("ai")
      d["stages"]["maintenance"]["by"].as_s.should eq("human")
      d["origin"]?.should be_nil
    end

    it "errors clearly when neither format is present" do
      _, err, _ = Rigor::Document.extract("just prose")
      err.not_nil!.should contain("Stamp")
    end
  end
end
