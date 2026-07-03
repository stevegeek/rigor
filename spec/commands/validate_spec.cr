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
    File.write(path, "---\nrigor: R3\nchecks:\n  security_reviewed: no\nvouch: neutral\n---\n")
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
end
