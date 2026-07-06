require "./spec_helper"

describe "schema/vocabulary drift" do
  it "vocabulary level names are exactly the schema rigor enum" do
    schema = JSON.parse(Rigor::Validator::SCHEMA_JSON)
    enum_vals = schema["properties"]["rigor"]["enum"].as_a.map(&.as_s)
    enum_vals.sort.should eq(Rigor::Vocabulary::LEVELS.sort)
  end

  it "check values match" do
    schema = JSON.parse(Rigor::Validator::SCHEMA_JSON)
    cv = schema["$defs"]["checkValue"]["enum"].as_a.map(&.as_s)
    cv.sort.should eq(Rigor::Vocabulary::CHECK_VALUES.sort)
  end
  it "maintenance activity values match" do
    schema = JSON.parse(Rigor::Validator::SCHEMA_JSON)
    av = schema["properties"]["stages"]["properties"]["maintenance"]["properties"]["activity"]["enum"].as_a.map(&.as_s)
    av.sort.should eq(Rigor::Vocabulary::ACTIVITY.sort)
  end
end
