require "../spec_helper"
require "file_utils"

describe Rigor::Commands::Init do
  it "scaffolds a valid human-first v0.2 RIGOR.md" do
    dir = File.tempname("init")
    Dir.mkdir(dir)
    stages = {"idea" => {"by" => "human", "depth" => "deep"}, "implementation" => {"by" => "ai"}}
    Rigor::Commands::Init.run(dir, "skimmed", "neutral", stages, "2026-07-05", false, IO::Memory.new).should eq(0)
    text = File.read(File.join(dir, "RIGOR.md"))
    text.lines.first.should eq("# Who made this, and how carefully")
    text.should contain(Rigor::Summary::MARKER_START)
    text.should contain("## Notes")
    text.should contain("## Stamp")
    text.index("## Stamp").not_nil!.should be > text.index("## Notes").not_nil!
    r = Rigor::Validator.validate(text)
    r.valid.should be_true
    r.warnings.join.should_not contain("spec version")
    FileUtils.rm_rf(dir)
  end

  it "still refuses to overwrite without --force" do
    dir = File.tempname("init2")
    Dir.mkdir(dir)
    File.write(File.join(dir, "RIGOR.md"), "x")
    Rigor::Commands::Init.run(dir, "comprehended", "neutral", {} of String => Hash(String, String), nil, false, IO::Memory.new).should eq(1)
    FileUtils.rm_rf(dir)
  end

  it "refuses to scaffold a structurally invalid vocabulary, and writes no file" do
    dir = File.tempname("init3")
    Dir.mkdir(dir)
    io = IO::Memory.new
    Rigor::Commands::Init.run(dir, "bogus", "neutral", {} of String => Hash(String, String), nil, false, io).should eq(1)
    File.exists?(File.join(dir, "RIGOR.md")).should be_false
    io.to_s.should contain("error")
    FileUtils.rm_rf(dir)
  end

  it "refuses to scaffold an engineered stamp whose checks are not surfaced" do
    dir = File.tempname("init4")
    Dir.mkdir(dir)
    io = IO::Memory.new
    Rigor::Commands::Init.run(dir, "engineered", "neutral", {} of String => Hash(String, String), nil, false, io).should eq(1)
    File.exists?(File.join(dir, "RIGOR.md")).should be_false
    io.to_s.should contain("show your working")
    FileUtils.rm_rf(dir)
  end

  it "scaffolds a vouch-why + dormant-maintenance RIGOR.md that validates and shows Why: in the summary" do
    dir = File.tempname("init5")
    Dir.mkdir(dir)
    stages = {"maintenance" => {"by" => "human", "activity" => "dormant"}}
    Rigor::Commands::Init.run(dir, "skimmed", "withheld", stages, "2026-07-05", false, IO::Memory.new,
      "fine for scripts, never audited").should eq(0)
    text = File.read(File.join(dir, "RIGOR.md"))
    r = Rigor::Validator.validate(text)
    r.valid.should be_true
    text.should contain("Why: fine for scripts, never audited")
    text.should contain(Rigor::Vocabulary::DORMANT_SENTENCE)
    FileUtils.rm_rf(dir)
  end
end
