module Rigor
  module Vocabulary
    LEVELS = %w[R0 R1 R2 R3 R4]

    LEVEL_NAMES = {
      "R0" => "none", "R1" => "surface", "R2" => "comprehended",
      "R3" => "engineered", "R4" => "owned",
    }

    NAME_TO_CODE = LEVEL_NAMES.invert

    # Neutral one-line definitions of what a level *means*. These describe the
    # claim, never assert that the work was done (that is what surfaced checks
    # are for). Used by `describe` alongside "author's claimed level".
    LEVEL_DEFINITION = {
      "R0" => "accepted without review",
      "R1" => "glanced at, not understood",
      "R2" => "understood and explainable",
      "R3" => "comprehended, quality- and security-reviewed, tested",
      "R4" => "R3 plus architectural ownership",
    }

    # Colors encode the R2 comprehension line: below it amber/red, R2+ green.
    LEVEL_COLOR = {
      "R0" => "#b91c1c", "R1" => "#c2410c", "R2" => "#15803d",
      "R3" => "#166534", "R4" => "#14532d",
    }

    VOUCH_COLOR = {
      "yes" => "#15803d", "neutral" => "#6b7280", "withheld" => "#b45309",
    }

    AUTHORED_GLOSS = {
      "human-crafted" => "first written by a human",
      "ai-assisted"   => "first written with AI assistance",
      "ai-generated"  => "first AI-generated",
    }

    MAINTENANCE_GLOSS = {
      "human-led" => "human-maintained",
      "ai-led"    => "AI-maintained with human direction",
      "ai-auto"   => "automatically maintained by an agent",
    }

    CHECK_KEYS   = %w[comprehended quality_reviewed security_reviewed tested owned]
    CHECK_VALUES = %w[yes no not-applicable]
    VOUCH_VALUES = %w[yes neutral withheld]
    AUTHORED     = %w[human-crafted ai-assisted ai-generated]
    MAINTENANCE  = %w[human-led ai-led ai-auto]

    # Checks each level implies. `tested` accepts not-applicable because the
    # spec's own R3 example relies on it. Consistency is one-way (see validator).
    LEVEL_REQUIRES = {
      "R0" => {} of String => Array(String),
      "R1" => {} of String => Array(String),
      "R2" => {"comprehended" => %w[yes]},
      "R3" => {
        "comprehended"      => %w[yes],
        "quality_reviewed"  => %w[yes],
        "security_reviewed" => %w[yes],
        "tested"            => %w[yes not-applicable],
      },
      "R4" => {
        "comprehended"      => %w[yes],
        "quality_reviewed"  => %w[yes],
        "security_reviewed" => %w[yes],
        "tested"            => %w[yes not-applicable],
        "owned"             => %w[yes],
      },
    }
  end
end
