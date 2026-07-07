// The Rigor/Vouch/Stages vocabulary: canonical names, first-person
// sentences, and the check requirements each level implies. Every string
// here is part of the spec's fixed vocabulary, so it is defined once and
// shared by the document parser, validator, and summary composer.

/** Names are the canonical encoding, and the only accepted vocabulary. */
export const LEVELS = ["unexamined", "skimmed", "comprehended", "engineered", "owned"];

/** Everything at or above the comprehension line. */
export const ABOVE_LINE = ["comprehended", "engineered", "owned"];

/**
 * The canonical first-person sentence for each claim. These are the spec's
 * voice: the RIGOR.md summary and README line are composed from them.
 * @type {Object<string, string>}
 */
export const LEVEL_SENTENCE = {
  unexamined: "I have not examined this code. It ran; that is all I claim.",
  skimmed:
    "I have run and skimmed this code, but I have not read it properly. No human has understood it line by line.",
  comprehended: "I have read and understood this code; I can explain every line of it.",
  engineered:
    "I understand this code; it was deliberately reviewed for quality and for security, issues found were fixed, and it has tests I trust.",
  owned: "I stand behind this code as soundly engineered and hold architectural responsibility for it.",
};

/** @type {Object<string, string>} */
export const VOUCH_SENTENCE = {
  yes: "I recommend this for use; I put my name behind it.",
  neutral: "I make no recommendation either way about depending on it.",
  withheld: "I am specifically not recommending you depend on this.",
};

export const STAGE_KEYS = ["idea", "plan", "implementation", "maintenance"];
export const DEPTHS = ["one-shot", "considered", "deep"];

/**
 * Whether the maintenance stage is currently active work or a dormant-but-
 * still-owned project (distinct from `by: none`, which means no one
 * responds at all).
 */
export const ACTIVITY = ["active", "dormant"];

export const DORMANT_SENTENCE =
  "Nothing has needed changing lately; I still use this and would respond if it broke.";

export const CHECK_KEYS = ["comprehended", "quality_reviewed", "security_reviewed", "tested", "owned"];
export const ACTORS = ["human", "human-with-ai", "ai"];
export const CHECK_DONE = ["yes", "human", "ai", "human-with-ai"];
export const CHECK_VALUES = ["yes", "human", "ai", "human-with-ai", "no", "not-applicable"];
export const VOUCH_VALUES = ["yes", "neutral", "withheld"];

/**
 * Checks each level implies, keyed by canonical name. `tested` accepts
 * not-applicable because the spec's own engineered example relies on it.
 * comprehended's acceptable set excludes `ai` alone because an AI
 * comprehending code does not put a human above the comprehension line.
 * @type {Object<string, Object<string, string[]>>}
 */
export const LEVEL_REQUIRES = {
  unexamined: {},
  skimmed: {},
  comprehended: { comprehended: ["yes", "human", "human-with-ai"] },
  engineered: {
    comprehended: ["yes", "human", "human-with-ai"],
    quality_reviewed: CHECK_DONE,
    security_reviewed: CHECK_DONE,
    tested: [...CHECK_DONE, "not-applicable"],
  },
  owned: {
    comprehended: ["yes", "human", "human-with-ai"],
    quality_reviewed: CHECK_DONE,
    security_reviewed: CHECK_DONE,
    tested: [...CHECK_DONE, "not-applicable"],
    owned: CHECK_DONE,
  },
};
