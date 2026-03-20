# frozen_string_literal: true

module UnicodeChars
  HYPHEN_MINUS = "-" # ASCII Hyphen-Minus (U+002D)
  HYPHEN = "\u2010" # Hyphen (U+2010) "‐"
  NB_HYPHEN = "\u2011" # Non-Breaking Hyphen (U+2011) "‑"
  EN_DASH = "\u2013" # En Dash (U+2013) ("–") Used in hansard text quite often
  EM_DASH = "\u2014" # Em Dash (U+2014) "—"
  DASHES = [HYPHEN_MINUS, HYPHEN, NB_HYPHEN, EN_DASH, EM_DASH].freeze
  NBSP = "\u00A0" # Non-Breaking Space (U+00A0) " "
end
