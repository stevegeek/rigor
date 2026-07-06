require "./spec_helper"

describe Rigor::Vocabulary do
  it "levels are the five v0.2 names, ordered" do
    Rigor::Vocabulary::LEVELS.should eq(%w[unexamined skimmed comprehended engineered owned])
  end

  it "has a first-person sentence for every level and vouch value" do
    Rigor::Vocabulary::LEVELS.each { |l| Rigor::Vocabulary::LEVEL_SENTENCE[l].should_not be_empty }
    Rigor::Vocabulary::VOUCH_VALUES.each { |v| Rigor::Vocabulary::VOUCH_SENTENCE[v].should_not be_empty }
  end

  it "level requirements are keyed by name" do
    Rigor::Vocabulary::LEVEL_REQUIRES["engineered"].keys.should contain("security_reviewed")
    Rigor::Vocabulary::LEVEL_REQUIRES["skimmed"].should be_empty
  end
end
