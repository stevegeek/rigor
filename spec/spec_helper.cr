require "spec"
require "../src/rigor"

def stamp_doc(yaml : String) : String
  "# T\n\n## Stamp\n\n```yaml\n#{yaml}\n```\n"
end
