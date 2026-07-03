require "../spec_helper"
require "file_utils"

describe Rigor::Commands::Init do
  it "writes a RIGOR.md that itself validates" do
    dir = File.tempname("rigor_init")
    Dir.mkdir_p(dir)
    io = IO::Memory.new
    code = Rigor::Commands::Init.run(dir, "R2", "neutral", nil, nil, force: false, io: io)
    code.should eq(0)
    path = File.join(dir, "RIGOR.md")
    File.exists?(path).should be_true
    Rigor::Validator.validate(File.read(path)).valid.should be_true
  ensure
    FileUtils.rm_rf(dir) if dir
  end

  it "refuses to overwrite an existing file without force" do
    dir = File.tempname("rigor_init2")
    Dir.mkdir_p(dir)
    File.write(File.join(dir, "RIGOR.md"), "existing")
    io = IO::Memory.new
    code = Rigor::Commands::Init.run(dir, "R2", "neutral", nil, nil, force: false, io: io)
    code.should eq(1)
    io.to_s.should contain("exists")
  ensure
    FileUtils.rm_rf(dir) if dir
  end
end
