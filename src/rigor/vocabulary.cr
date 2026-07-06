module Rigor
  module Vocabulary
    # Names are the canonical encoding, and the only accepted vocabulary.
    LEVELS = %w[unexamined skimmed comprehended engineered owned]

    # Everything at or above the comprehension line.
    ABOVE_LINE = %w[comprehended engineered owned]

    # The canonical first-person sentence for each claim. These are the spec's
    # voice: the RIGOR.md summary and README line are composed from them.
    LEVEL_SENTENCE = {
      "unexamined"   => "I have not examined this code. It ran; that is all I claim.",
      "skimmed"      => "I have run and skimmed this code, but I have not read it properly. No human has understood it line by line.",
      "comprehended" => "I have read and understood this code; I can explain every line of it.",
      "engineered"   => "I understand this code; it was deliberately reviewed for quality and for security, issues found were fixed, and it has tests I trust.",
      "owned"        => "I stand behind this code as soundly engineered and hold architectural responsibility for it.",
    }

    VOUCH_SENTENCE = {
      "yes"      => "I recommend this for use; I put my name behind it.",
      "neutral"  => "I make no recommendation either way about depending on it.",
      "withheld" => "I am specifically not recommending you depend on this.",
    }

    STAGE_KEYS = %w[idea plan implementation maintenance]
    DEPTHS     = %w[one-shot considered deep]

    # Whether the maintenance stage is currently active work or a dormant-but-
    # still-owned project (distinct from `by: none`, which means no one
    # responds at all).
    ACTIVITY = %w[active dormant]

    DORMANT_SENTENCE = "Nothing has needed changing lately; I still use this and would respond if it broke."

    CHECK_KEYS   = %w[comprehended quality_reviewed security_reviewed tested owned]
    ACTORS       = %w[human human-with-ai ai]
    CHECK_DONE   = %w[yes human ai human-with-ai]
    CHECK_VALUES = %w[yes human ai human-with-ai no not-applicable]
    VOUCH_VALUES = %w[yes neutral withheld]

    # Checks each level implies, keyed by canonical name. `tested` accepts
    # not-applicable because the spec's own engineered example relies on it.
    # comprehended's acceptable set excludes `ai` alone because an AI
    # comprehending code does not put a human above the comprehension line.
    LEVEL_REQUIRES = {
      "unexamined"   => {} of String => Array(String),
      "skimmed"      => {} of String => Array(String),
      "comprehended" => {"comprehended" => %w[yes human human-with-ai]},
      "engineered"   => {
        "comprehended"      => %w[yes human human-with-ai],
        "quality_reviewed"  => CHECK_DONE,
        "security_reviewed" => CHECK_DONE,
        "tested"            => CHECK_DONE + %w[not-applicable],
      },
      "owned" => {
        "comprehended"      => %w[yes human human-with-ai],
        "quality_reviewed"  => CHECK_DONE,
        "security_reviewed" => CHECK_DONE,
        "tested"            => CHECK_DONE + %w[not-applicable],
        "owned"             => CHECK_DONE,
      },
    }
  end
end
