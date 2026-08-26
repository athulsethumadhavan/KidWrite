# Letter artwork (optional)

Drop a PNG here named after the character id and it replaces the emoji on the
reward card for that letter. Everything else keeps its emoji, so the set can be
filled in one letter at a time.

    assets/words/en_lower_A.png     → shown instead of 🍎 for "A for Apple"
    assets/words/ml_vowel_0.png     → shown instead of 👩 for "അ … അമ്മ"

Ids come from `character_local_datasource.dart`:

  english upper   en_lower_A … en_lower_Z   (capital letter in the name)
  english lower   en_lower_a … en_lower_z
  numbers         num_0 … num_9
  malayalam       ml_vowel_0 … ml_vowel_14, ml_cons_0 … ml_cons_35

Roughly square, transparent background, 512×512 or larger. The card scales
them to fit, so exact size does not matter.
