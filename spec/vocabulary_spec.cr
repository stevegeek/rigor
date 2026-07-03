require "./spec_helper"

describe Rigor::Vocabulary do
  it "has five levels R0..R4" do
    Rigor::Vocabulary::LEVELS.should eq(%w[R0 R1 R2 R3 R4])
  end

  it "maps names to codes and back consistently" do
    Rigor::Vocabulary::LEVEL_NAMES.each do |code, name|
      Rigor::Vocabulary::NAME_TO_CODE[name].should eq(code)
    end
  end

  it "requires comprehended at R2 and owned at R4" do
    Rigor::Vocabulary::LEVEL_REQUIRES["R2"]["comprehended"].should eq(%w[yes])
    Rigor::Vocabulary::LEVEL_REQUIRES["R4"]["owned"].should eq(%w[yes])
    Rigor::Vocabulary::LEVEL_REQUIRES["R3"]["tested"].should eq(%w[yes not-applicable])
  end
end
