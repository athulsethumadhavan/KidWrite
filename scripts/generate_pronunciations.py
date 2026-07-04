"""
KidWrite — Letter Pronunciation Audio Generator
================================================
Run this ONCE on any machine with internet access:

    pip install gtts
    python scripts/generate_pronunciations.py

It generates 187 MP3 files into assets/audio/letters/
using Google Text-to-Speech, one per character ID.
The Flutter app plays <id>.mp3 on success.
"""

from gtts import gTTS
import os, sys, time

# Output path relative to this script's location (project root)
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(SCRIPT_DIR, '..', 'assets', 'audio', 'letters')
os.makedirs(OUT, exist_ok=True)

def speak(char_id: str, text: str, lang: str, slow: bool = False):
    path = os.path.join(OUT, f'{char_id}.mp3')
    if os.path.exists(path):
        print(f'  skip  {char_id}.mp3 (already exists)')
        return
    try:
        gTTS(text=text, lang=lang, slow=slow).save(path)
        print(f'  ✓  {char_id}.mp3  [{lang}] "{text}"')
        time.sleep(0.15)   # polite delay to avoid rate-limiting
    except Exception as e:
        print(f'  ✗  {char_id}  ERROR: {e}', file=sys.stderr)

# ── English uppercase A-Z ─────────────────────────────────────────────────
upper = [
    ('A','ay'),('B','bee'),('C','see'),('D','dee'),('E','ee'),('F','ef'),
    ('G','jee'),('H','aych'),('I','eye'),('J','jay'),('K','kay'),('L','el'),
    ('M','em'),('N','en'),('O','oh'),('P','pee'),('Q','cue'),('R','ar'),
    ('S','ess'),('T','tee'),('U','you'),('V','vee'),('W','double you'),
    ('X','ex'),('Y','why'),('Z','zee'),
]
print('\n— English uppercase —')
for sym, pron in upper:
    speak(f'en_upper_{sym}', pron, 'en')  # single sound, e.g. "ay" 

# ── English lowercase a-z ─────────────────────────────────────────────────
lower = [
    ('a','ay'),('b','bee'),('c','see'),('d','dee'),('e','ee'),('f','ef'),
    ('g','jee'),('h','aych'),('i','eye'),('j','jay'),('k','kay'),('l','el'),
    ('m','em'),('n','en'),('o','oh'),('p','pee'),('q','cue'),('r','ar'),
    ('s','ess'),('t','tee'),('u','you'),('v','vee'),('w','double you'),
    ('x','ex'),('y','why'),('z','zee'),
]
print('\n— English lowercase —')
for sym, pron in lower:
    speak(f'en_lower_{sym}', pron, 'en')  # single sound, e.g. "ay" 

# ── Numbers 0-9 ───────────────────────────────────────────────────────────
numbers = ['zero','one','two','three','four','five','six','seven','eight','nine']
print('\n— Numbers —')
for i, name in enumerate(numbers):
    speak(f'num_{i}', name, 'en')

# ── Malayalam vowels ──────────────────────────────────────────────────────
ml_vowels = ['അ','ആ','ഇ','ഈ','ഉ','ഊ','എ','ഏ','ഐ','ഒ','ഓ','ഔ']
print('\n— Malayalam vowels —')
for i, sym in enumerate(ml_vowels):
    speak(f'ml_vowel_{i}', sym, 'ml', slow=True)

# ── Malayalam consonants ──────────────────────────────────────────────────
ml_cons = [
    'ക','ഖ','ഗ','ഘ','ങ','ച','ഛ','ജ','ഝ','ഞ',
    'ട','ഠ','ഡ','ഢ','ണ','ത','ഥ','ദ','ധ','ന',
    'പ','ഫ','ബ','ഭ','മ','യ','ര','ല','വ','ശ',
    'ഷ','സ','ഹ','ള','ഴ','റ',
]
print('\n— Malayalam consonants —')
for i, sym in enumerate(ml_cons):
    speak(f'ml_cons_{i}', sym, 'ml', slow=True)

# ── Hindi vowels ──────────────────────────────────────────────────────────
hi_vowels = ['अ','आ','इ','ई','उ','ऊ','ए','ऐ','ओ','औ']
print('\n— Hindi vowels —')
for i, sym in enumerate(hi_vowels):
    speak(f'hi_vowel_{i}', sym, 'hi', slow=True)

# ── Hindi consonants ──────────────────────────────────────────────────────
hi_cons = [
    'क','ख','ग','घ','ङ','च','छ','ज','झ','ञ',
    'ट','ठ','ड','ढ','ण','त','थ','द','ध','न',
    'प','फ','ब','भ','म','य','र','ल','व','श',
    'ष','स','ह',
]
print('\n— Hindi consonants —')
for i, sym in enumerate(hi_cons):
    speak(f'hi_cons_{i}', sym, 'hi', slow=True)

# ── Tamil vowels ──────────────────────────────────────────────────────────
ta_vowels = ['அ','ஆ','இ','ஈ','உ','ஊ','எ','ஏ','ஐ','ஒ','ஓ','ஔ']
print('\n— Tamil vowels —')
for i, sym in enumerate(ta_vowels):
    speak(f'ta_vowel_{i}', sym, 'ta', slow=True)

# ── Tamil consonants ──────────────────────────────────────────────────────
ta_cons = [
    'க','ங','ச','ஞ','ட','ண','த','ந','ப','ம',
    'ய','ர','ல','வ','ழ','ள','ற','ன','ஜ','ஷ',
    'ஸ','ஹ',
]
print('\n— Tamil consonants —')
for i, sym in enumerate(ta_cons):
    speak(f'ta_cons_{i}', sym, 'ta', slow=True)

total = len([f for f in os.listdir(OUT) if f.endswith('.mp3')])
print(f'\n✓ Done — {total}/187 files in assets/audio/letters/')
