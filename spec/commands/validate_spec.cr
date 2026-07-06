require "../spec_helper"

describe Rigor::Commands::Validate do
  it "returns 0 and prints valid for a good file" do
    io = IO::Memory.new
    code = Rigor::Commands::Validate.run("spec/fixtures/minimal.md", strict: false, json: false, io: io)
    code.should eq(0)
    io.to_s.should contain("valid: true")
  end

  it "returns 1 for a contradicting file" do
    path = File.tempname("rigor", ".md")
    File.write(path, stamp_doc("rigor: engineered\nchecks:\n  security_reviewed: no\nvouch: neutral"))
    io = IO::Memory.new
    code = Rigor::Commands::Validate.run(path, strict: false, json: false, io: io)
    code.should eq(1)
  ensure
    File.delete(path) if path
  end

  it "emits JSON with --json" do
    io = IO::Memory.new
    Rigor::Commands::Validate.run("spec/fixtures/minimal.md", strict: false, json: true, io: io)
    parsed = JSON.parse(io.to_s)
    parsed["valid"].as_bool.should be_true
  end

  it "includes the stamp's spec version in --json output" do
    io = IO::Memory.new
    Rigor::Commands::Validate.run("spec/fixtures/minimal_v2.md", strict: false, json: true, io: io)
    parsed = JSON.parse(io.to_s)
    parsed["spec_version"].as_s.should eq("0.3")
  end

  it "reports spec_version as null when the stamp has no spec field" do
    path = File.tempname("rigor", ".md")
    File.write(path, stamp_doc("rigor: skimmed\nvouch: neutral"))
    io = IO::Memory.new
    Rigor::Commands::Validate.run(path, strict: false, json: true, io: io)
    parsed = JSON.parse(io.to_s)
    parsed["spec_version"].raw.should be_nil
  ensure
    File.delete(path) if path
  end

  it "exits 1 and mentions README when the --readme line has drifted from the stamp" do
    stamp_path = File.tempname("rigor", ".md")
    readme_path = File.tempname("readme", ".md")
    d, _ = Rigor::Document.extract(File.read("spec/fixtures/minimal.md"))
    File.write(stamp_path, File.read("spec/fixtures/minimal.md"))
    stale_block = Rigor::Summary.line_block(d.not_nil!).sub("read and understood this code", "skimmed this code")
    File.write(readme_path, "# P\n\n#{stale_block}\n")
    io = IO::Memory.new
    code = Rigor::Commands::Validate.run(stamp_path, strict: false, json: false, io: io, readme: readme_path)
    code.should eq(1)
    io.to_s.should contain("README")
  ensure
    File.delete(stamp_path) if stamp_path
    File.delete(readme_path) if readme_path
  end

  it "exits 0 when the --readme line matches the stamp" do
    stamp_path = File.tempname("rigor", ".md")
    readme_path = File.tempname("readme", ".md")
    File.write(stamp_path, File.read("spec/fixtures/minimal.md"))
    d, _ = Rigor::Document.extract(File.read("spec/fixtures/minimal.md"))
    File.write(readme_path, "# P\n\n#{Rigor::Summary.line_block(d.not_nil!)}\n")
    io = IO::Memory.new
    code = Rigor::Commands::Validate.run(stamp_path, strict: false, json: false, io: io, readme: readme_path)
    code.should eq(0)
  ensure
    File.delete(stamp_path) if stamp_path
    File.delete(readme_path) if readme_path
  end

  it "exits 0 silently when the --readme file has no line markers" do
    stamp_path = File.tempname("rigor", ".md")
    readme_path = File.tempname("readme", ".md")
    File.write(stamp_path, File.read("spec/fixtures/minimal.md"))
    File.write(readme_path, "# P\nno markers here\n")
    io = IO::Memory.new
    code = Rigor::Commands::Validate.run(stamp_path, strict: false, json: false, io: io, readme: readme_path)
    code.should eq(0)
    io.to_s.should_not contain("README")
  ensure
    File.delete(stamp_path) if stamp_path
    File.delete(readme_path) if readme_path
  end
end
