"""
KidWrite — Reward-word audio generator
======================================
Makes the "A for Apple" / "അമ്മ" clips the reward card plays.

    pip install gtts
    python scripts/generate_word_audio.py            # only what is missing
    python scripts/generate_word_audio.py --force    # redo everything
    python scripts/generate_word_audio.py --slow     # slower, clearer voice

Writes assets/audio/words/<character id>.mp3. The app prefers these files and
only falls back to the device's text-to-speech voice when one is missing —
which matters most for Malayalam, since iOS has no Malayalam voice at all and
Android only has one if the user installed it.

Nothing is hard-coded here: the words come from
    lib/Core/data/letter_words.dart
and the ids from
    lib/data/datasources/character_local_datasource.dart
so this stays correct if either list is edited. Existing files are skipped, so
it is safe to re-run after adding a few words.
"""

import os
import re
import sys
import time

try:
    from gtts import gTTS
except ImportError:
    sys.exit('pip install gtts')

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
WORDS_DART = os.path.join(ROOT, 'lib', 'Core', 'data', 'letter_words.dart')
CHARS_DART = os.path.join(
    ROOT, 'lib', 'data', 'datasources', 'character_local_datasource.dart')
OUT = os.path.join(ROOT, 'assets', 'audio', 'words')
os.makedirs(OUT, exist_ok=True)

FORCE = '--force' in sys.argv
# gTTS's slow mode is a lot easier to follow for a child, at the cost of
# sounding drawn out. Off by default; try it if a word is hard to make out.
SLOW = '--slow' in sys.argv


def read(path):
    with open(path, encoding='utf-8') as fh:
        return fh.read()


def block(text, start_marker, end_marker='];'):
    """The source between a list declaration and its closing bracket."""
    i = text.index(start_marker)
    return text[i:text.index(end_marker, i)]


# ── words ────────────────────────────────────────────────────────────────────
words_src = read(WORDS_DART)

english = re.findall(
    r"\['([A-Z])', '([^']+)', '[^']+'\]", block(words_src, '_english = ['))

malayalam = re.findall(
    r"\['([^']+)', '([^']+)', '([^']+)', '[^']+'\]",
    block(words_src, '_ml = ['))

numbers = re.findall(
    r"\['([a-z]+)', '([a-z]*)', '[^']+'\]",
    block(words_src, '_numberItems = ['))

# ── ids: the Malayalam symbol order decides ml_vowel_N / ml_cons_N ───────────
chars_src = read(CHARS_DART)
ml_vowels = re.findall(
    r"\['([ഀ-ൿ]+)', '[^']*', '[^']*'\]",
    block(chars_src, 'final vowels = ['))
ml_cons = re.findall(
    r"\['([ഀ-ൿ]+)', '[^']*', '[^']*'\]",
    block(chars_src, 'final consonants = ['))

ml_id = {}
for i, sym in enumerate(ml_vowels):
    ml_id[sym] = f'ml_vowel_{i}'
for i, sym in enumerate(ml_cons):
    ml_id[sym] = f'ml_cons_{i}'

# ── build the job list ───────────────────────────────────────────────────────
jobs = []  # (id, text, lang)

for sym, word in english:
    # Capitals get their own prefix on purpose: the character ids put both
    # cases under en_lower_, and en_lower_A / en_lower_a are the same file on
    # macOS and Windows. Matches LetterWords.fileStem in the app.
    jobs.append((f'en_upper_{sym}', f'{sym} for {word}', 'en'))
    low = sym.lower()
    jobs.append((f'en_lower_{low}', f'{low} for {word.lower()}', 'en'))

for n, (name, item) in enumerate(numbers):
    # "one cat", "eight snails" — zero has nothing to count.
    jobs.append((f'num_{n}', name if not item else f'{name} {item}', 'en'))

missing = []
for sym, word, roman in malayalam:
    cid = ml_id.get(sym)
    if cid is None:
        missing.append(sym)
        continue
    # Letter first, then the word. The comma matters: without a pause gTTS
    # runs the bare vowel straight into the word and it turns to mush.
    jobs.append((cid, f'{sym}, {word}', 'ml'))

if missing:
    print('!! not in the character list, skipped:', ' '.join(missing),
          file=sys.stderr)

# ── generate ─────────────────────────────────────────────────────────────────
flags = ''.join([
    '  (--force: overwriting)' if FORCE else '',
    '  (--slow)' if SLOW else '',
])
print(f'{len(jobs)} clips → {os.path.normpath(OUT)}{flags}\n')
made = skipped = failed = 0

for cid, text, lang in jobs:
    path = os.path.join(OUT, f'{cid}.mp3')
    if os.path.exists(path) and not FORCE:
        skipped += 1
        continue
    try:
        gTTS(text=text, lang=lang, slow=SLOW).save(path)
        made += 1
        print(f'  ✓  {cid}.mp3  [{lang}] "{text}"')
        time.sleep(0.15)   # polite delay, gTTS rate-limits
    except Exception as exc:                      # noqa: BLE001
        failed += 1
        print(f'  ✗  {cid}  {exc}', file=sys.stderr)

print(f'\ndone — {made} new, {skipped} already there, {failed} failed')
