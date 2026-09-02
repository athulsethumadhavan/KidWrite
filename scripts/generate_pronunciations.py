"""
KidWrite — Letter pronunciation audio
=====================================
Makes the clip that plays when a child opens a letter.

    pip install gtts
    python scripts/generate_pronunciations.py            # only what is missing
    python scripts/generate_pronunciations.py --force    # redo everything
    python scripts/generate_pronunciations.py --slow     # slower, clearer voice

Writes assets/audio/letters/<file stem>.mp3, plus a manifest.json recording
which letter each clip belongs to.

Nothing is hard-coded here. The character list comes from
    lib/data/datasources/character_local_datasource.dart

That matters more than it sounds. This script used to keep its own copy of
every alphabet, and when ഋ and ऋ were added to the tables the copies were not
updated — so ml_vowel_6.mp3 went on saying എ while the app showed ഋ, and every
vowel after it was shifted by one. Six of twelve Malayalam clips and four of
ten Hindi ones were playing the wrong letter. Deriving the list from the app is
what stops that recurring; the manifest is what makes it visible if it does
(see test/letter_audio_test.dart).
"""

import json
import os
import re
import sys
import time

try:
    from gtts import gTTS
except ImportError:
    sys.exit('pip install gtts')

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
CHARS = os.path.join(ROOT, 'lib', 'data', 'datasources',
                     'character_local_datasource.dart')
OUT = os.path.join(ROOT, 'assets', 'audio', 'letters')
os.makedirs(OUT, exist_ok=True)

FORCE = '--force' in sys.argv
SLOW = '--slow' in sys.argv

src = open(CHARS, encoding='utf-8').read()


def block(text, marker, after=0):
    """The source between a list declaration and its closing bracket."""
    i = text.index(marker, after)
    return text[i:text.index('];', i)]


def rows(marker, after=0):
    """Every ['a', 'b', ...] row inside that list."""
    return [re.findall(r"'((?:[^'\\]|\\.)*)'", line)
            for line in block(marker, after).splitlines()
            if line.strip().startswith('[')]


def block_from(fn, marker):
    """A list inside a particular builder.

    Anchored on the *definition*, not the name: every builder is also named in
    the switch near the top of the file, and starting there would find whichever
    list came first — which is how Hindi and Tamil both ended up reading
    Malayalam's vowels.
    """
    return block(src, marker, src.index(f'List<CharacterModel> {fn}'))


def rows_from(fn, marker):
    return [re.findall(r"'((?:[^'\\]|\\.)*)'", line)
            for line in block_from(fn, marker).splitlines()
            if line.strip().startswith('[')]


jobs = []      # (file stem, text to say, gTTS language)
manifest = {}  # file stem -> the symbol it belongs to


def add(stem, symbol, text, lang):
    jobs.append((stem, text, lang))
    manifest[stem] = symbol


# ── lines and shapes: no sayable symbol, so the description is spoken ────────
for i, r in enumerate(rows_from('_lineCharacters', 'final data = [')):
    add(f'line_{r[3]}', r[0], r[2], 'en')
for i, r in enumerate(rows_from('_shapeCharacters', 'final data = [')):
    add(f'shape_{r[2]}', r[0], r[2], 'en')

# ── English and numbers: the symbol, never the written hint ─────────────────
# gTTS says the letter's name when given "A" and reads the word "aye" when
# given the hint "ay". The hint column is for the printed label under the
# letter, not for speech - LetterAudioService._speakFallback makes the same
# distinction, and these clips must agree with it.
for r in rows_from('_englishCharacters', 'final uppercaseData = ['):
    add(f'en_upper_{r[0]}', r[0], r[0], 'en')
for r in rows_from('_englishCharacters', 'final lowercaseData = ['):
    add(f'en_lower_{r[0]}', r[0], r[0], 'en')
for r in rows_from('_numberCharacters', 'final data = ['):
    add(f'num_{r[0]}', r[0], r[0], 'en')

# ── Indic scripts: the symbol itself, read in its own voice ─────────────────
for fn, prefix, lang in [('_malayalamCharacters', 'ml', 'ml'),
                         ('_hindiCharacters', 'hi', 'hi'),
                         ('_tamilCharacters', 'ta', 'ta')]:
    for kind, marker in [('vowel', 'final vowels = ['),
                         ('cons', 'final consonants = [')]:
        for i, r in enumerate(rows_from(fn, marker)):
            add(f'{prefix}_{kind}_{i}', r[0], r[0], lang)

# ── what is stale ───────────────────────────────────────────────────────────
# A clip is only trustworthy if the last run recorded it against the same
# letter. Anything the manifest disagrees with - or predates - is regenerated
# whether or not --force was passed, because those are exactly the files that
# play the wrong letter and would otherwise be skipped forever.
MANIFEST = os.path.join(OUT, 'manifest.json')
try:
    with open(MANIFEST, encoding='utf-8') as fh:
        known = json.load(fh)
except (OSError, ValueError):
    known = {}
stale = {stem for stem, symbol in manifest.items() if known.get(stem) != symbol}
if stale and known:
    print(f'{len(stale)} clip(s) no longer match the letter they were made for')
elif not known:
    print('no manifest from a previous run — every clip will be remade once')

# ── generate ────────────────────────────────────────────────────────────────
flags = ''.join(['  (--force: overwriting)' if FORCE else '',
                 '  (--slow)' if SLOW else ''])
print(f'{len(jobs)} clips → {os.path.normpath(OUT)}{flags}\n')
made = skipped = failed = 0

for stem, text, lang in jobs:
    path = os.path.join(OUT, f'{stem}.mp3')
    if os.path.exists(path) and not FORCE and stem not in stale:
        skipped += 1
        continue
    try:
        gTTS(text=text, lang=lang, slow=SLOW).save(path)
        made += 1
        print(f'  ✓  {stem}.mp3  [{lang}] "{text}"')
        time.sleep(0.15)   # polite delay, gTTS rate-limits
    except Exception as exc:                      # noqa: BLE001
        failed += 1
        print(f'  ✗  {stem}  {exc}', file=sys.stderr)

with open(os.path.join(OUT, 'manifest.json'), 'w', encoding='utf-8') as fh:
    json.dump(manifest, fh, ensure_ascii=False, indent=1, sort_keys=True)

print(f'\ndone — {made} new, {skipped} already there, {failed} failed')
print(f'manifest: {len(manifest)} clips')
