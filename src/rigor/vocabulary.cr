module Rigor
  module Vocabulary
    # v0.2: names are the canonical encoding, and the only accepted vocabulary.
    LEVELS = %w[unexamined skimmed comprehended engineered owned]

    # Everything at or above the comprehension line.
    ABOVE_LINE = %w[comprehended engineered owned]

    # The canonical first-person sentence for each claim. These are the spec's
    # voice: summaries, badges' <desc>, and the /r page are composed from them.
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

    # Short badge/infobox wording for vouch.
    VOUCH_LABEL = {"yes" => "vouched", "neutral" => "no vouch", "withheld" => "vouch withheld"}

    # Short gloss for the infobox (340px wide; sentences don't fit).
    LEVEL_GLOSS = {
      "unexamined"   => "not examined by a human",
      "skimmed"      => "run and skimmed, not read",
      "comprehended" => "understood line by line",
      "engineered"   => "reviewed, security-checked, tested",
      "owned"        => "engineered and owned",
    }

    # Below the comprehension line: neutral slate — an honest low stamp must
    # not look like a warning sticker. At/above the line: blue, then greens.
    LEVEL_COLOR = {
      "unexamined"   => "#64748b",
      "skimmed"      => "#64748b",
      "comprehended" => "#0369a1",
      "engineered"   => "#15803d",
      "owned"        => "#14532d",
    }

    VOUCH_COLOR = {
      "yes" => "#15803d", "neutral" => "#6b7280", "withheld" => "#334155",
    }

    STAGE_KEYS = %w[idea plan implementation maintenance]
    DEPTHS     = %w[one-shot considered deep]

    # Short display forms for the infobox stage story.
    STAGE_LABEL = {"idea" => "Idea", "plan" => "Plan", "implementation" => "Implementation", "maintenance" => "Maintenance"}
    BY_SHORT    = {"human" => "me", "human-with-ai" => "me + AI", "ai" => "AI", "none" => "no one"}
    DEPTH_SHORT = {"one-shot" => "one-shot", "considered" => "thought through", "deep" => "worked in depth"}

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
