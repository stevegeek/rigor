require "./spec_helper"

describe "schema/vocabulary drift" do
  it "vocabulary level codes are all present in the schema rigor enum" do
    schema = JSON.parse(Rigor::Validator::SCHEMA_JSON)
    enum_vals = schema["properties"]["rigor"]["enum"].as_a.map(&.as_s)
    Rigor::Vocabulary::LEVELS.each { |code| enum_vals.should contain(code) }
    Rigor::Vocabulary::LEVEL_NAMES.values.each { |name| enum_vals.should contain(name) }
  end

  it "check values match" do
    schema = JSON.parse(Rigor::Validator::SCHEMA_JSON)
    cv = schema["$defs"]["checkValue"]["enum"].as_a.map(&.as_s)
    cv.sort.should eq(Rigor::Vocabulary::CHECK_VALUES.sort)
  end
end
