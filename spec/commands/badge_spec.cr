require "../spec_helper"

describe Rigor::Commands::Badge do
  it "renders a badge from a file to the given io" do
    io = IO::Memory.new
    code = Rigor::Commands::Badge.run("spec/fixtures/full_r3.md", nil, infobox: false, out_path: nil, io: io)
    code.should eq(0)
    io.to_s.should contain("<svg")
    io.to_s.should contain("rigor engineered")
  end

  it "renders from --params" do
    io = IO::Memory.new
    code = Rigor::Commands::Badge.run(nil, "rigor=R2&vouch=neutral", infobox: false, out_path: nil, io: io)
    code.should eq(0)
    io.to_s.should contain("rigor comprehended")
  end

  it "renders an invalid badge (exit 1) for bad params" do
    io = IO::Memory.new
    code = Rigor::Commands::Badge.run(nil, "rigor=R9&vouch=yes", infobox: false, out_path: nil, io: io)
    code.should eq(1)
    io.to_s.should contain("rigor: invalid")
  end
end
