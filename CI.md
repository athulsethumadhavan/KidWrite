# CI/CD

Two branches, two jobs.

| Event | What runs | Where |
|---|---|---|
| push / PR → `dev` | format, analyze, unit + widget tests | `.github/workflows/dev.yml` |
| push → `main` | the same gate, then Play + App Store upload, then the docs | `.github/workflows/release.yml` |

Local `git push` runs the same gate first — see [Pre-push hook](#pre-push-hook).

---

## One thing to know first

**A push cannot be rejected by CI.** Git either accepts it or it doesn't; by the
time a workflow runs, the commit is already on the branch. "Only push to dev if
the tests pass" is really two separate mechanisms, and you want both:

1. **The pre-push hook** stops a bad push on your own machine, before it leaves.
2. **Branch protection** stops bad code reaching `dev`/`main` from anywhere else
   — another machine, the GitHub web editor, a collaborator.

Set both up. The hook is convenience; branch protection is the actual rule.

### Branch protection

GitHub → **Settings → Branches → Add rule**, once for `dev` and once for `main`:

- Branch name pattern: `dev`
- ☑ Require a pull request before merging
- ☑ Require status checks to pass before merging → search for and select
  **`analyze and test`**
- ☑ Require branches to be up to date before merging

Repeat for `main`, and there also tick **Do not allow bypassing the above
settings** so a rushed `git push main` can't skip the gate.

With this on, the flow becomes: work on a feature branch → PR into `dev` →
checks go green → merge. Then PR `dev` → `main` when you want to ship.

### Pre-push hook

Enable once per clone:

```bash
git config core.hooksPath .githooks
```

It only guards `dev` and `main`, takes a few seconds, and `git push --no-verify`
skips it when you need to.

---

## Tests

```bash
flutter test                              # unit + widget, ~seconds, no device
flutter test integration_test/app_test.dart   # end-to-end, needs a device
```

| File | Covers |
|---|---|
| `test/character_data_test.dart` | the letter tables — counts, unique ids, ordering, and that `unlockAllLetters` is `false` |
| `test/letter_words_test.dart` | every letter has a picture-word; asset filenames don't collide case-insensitively |
| `test/letter_audio_test.dart` | every clip is still filed under the letter it was recorded for |
| `test/letter_strokes_test.dart` | the Latin, shape and line paths; and that nothing Indic leaks into that table |
| `test/malayalam_strokes_test.dart` | all 51 paths present, in range, no points too close together to give the hand a direction |
| `test/hindi_strokes_test.dart` | all 13 vowels and all 33 consonants guided; same geometry checks, plus the shirorekha being drawn last |
| `test/progress_test.dart` | stars, unlocking, and that every mutable field is in `props` |
| `test/letter_reward_card_test.dart` | the reward card renders and dismisses |
| `integration_test/app_test.dart` | home → letter map → practice screen, on a real device |

Everything except the integration test runs in CI. Integration tests need an
emulator, which roughly triples the job time — worth adding once the suite is
worth the wait.

`letter_audio_test` is the odd one: it guards *files*, not code. The clips are
named by index (`ml_vowel_6.mp3`), so inserting a letter into the middle of a
table silently renumbers every clip after it. That happened — ten clips went on
playing the letter that used to hold their index and nothing failed. The
generator now writes a manifest and this test compares it with the live table.

Two of these are release guards rather than correctness tests: the
`unlockAllLetters` check and the version-agreement check in the release
workflow. Both catch mistakes that have actually shipped before.

---

## Fastlane

```bash
cd android && bundle install
cd ios     && bundle install
```

| Lane | Does |
|---|---|
| `cd android && bundle exec fastlane internal` | test → build → Play internal track, as a draft |
| `cd android && bundle exec fastlane production` | test → build → Play production at **20% rollout** |
| `cd android && bundle exec fastlane current_version` | prints the highest versionCode Play has seen |
| `cd ios && bundle exec fastlane beta` | test → build → TestFlight |
| `cd ios && bundle exec fastlane release` | test → build → App Store, submitted for review, **held for manual release** |

Both release lanes hold rather than auto-publish. That is deliberate: the docs
job flips `version.json`, which prompts every existing user to update. If the
build were auto-released and then rejected, the prompt would point at nothing.

---

## Secrets

GitHub → **Settings → Secrets and variables → Actions**.

### Android

| Secret | How to get it |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -i android/kid_write-keystore.jks \| pbcopy` |
| `ANDROID_KEY_ALIAS` | the `keyAlias` line in your local `android/local.properties` |
| `ANDROID_KEY_PASSWORD` | `keyPassword` from the same file |
| `ANDROID_STORE_PASSWORD` | `storePassword` from the same file |
| `PLAY_STORE_JSON_KEY` | Create the service account in Google Cloud Console → IAM → Service Accounts, download its JSON key, then invite that account's email under Play Console → Users and permissions with release permissions on KidWrite. Paste the whole file. (Google retired the old Setup → API access page.) |

### iOS

| Secret | How to get it |
|---|---|
| `APPLE_ID` | your Apple ID email |
| `APPLE_TEAM_ID` | Developer portal → Membership |
| `APPLE_ITC_TEAM_ID` | `fastlane produce --help`, or App Store Connect → Users |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect → Users and Access → Integrations → App Store Connect API → generate a key |
| `APP_STORE_CONNECT_ISSUER_ID` | shown on the same page |
| `APP_STORE_CONNECT_KEY_CONTENT` | `base64 -i AuthKey_XXXX.p8 \| pbcopy` |
| `MATCH_GIT_URL` | SSH URL of the private certificates repo, e.g. `git@github.com:athulsethumadhavan/kidwrite-certificates.git` |
| `MATCH_PASSWORD` | the passphrase you chose the first time you ran `match appstore` — lose it and the repo has to be regenerated |
| `MATCH_DEPLOY_KEY` | private half of an SSH key pair; the public half goes on the certificates repo as a read-only deploy key |

`APPLE_ITC_TEAM_ID` is usually unnecessary once the API key is in place. Leave
it unset unless a build complains about ambiguous teams.

### Code signing

A macOS runner starts with an empty keychain, so the distribution certificate
has to come from somewhere. `match` keeps it and the provisioning profile
AES-encrypted in a private git repo and installs them at build time. Every
machine then signs with the *same* certificate instead of each minting its own
and exhausting the three Apple allows.

First-time setup, from your Mac (the one that already has the certificate):

```bash
# 1. Create an empty PRIVATE repo on GitHub: kidwrite-certificates
# 2. Generate a deploy key for CI to read it with
ssh-keygen -t ed25519 -f ~/.ssh/kidwrite_match -N ""
#    public half  → repo → Settings → Deploy keys → Add (read-only)
#    private half → MATCH_DEPLOY_KEY secret:  pbcopy < ~/.ssh/kidwrite_match

# 3. Populate it. Choose a passphrase and keep it — that is MATCH_PASSWORD.
cd ios && bundle exec fastlane match appstore
```

Run `match appstore` by hand again whenever the certificate expires (a year).
CI is `readonly` and will never create or revoke one.

The keystore, the `.p8` and `play-store-key.json` are all in `.gitignore`.
None of them has ever been committed — I checked. Keep it that way: a leaked
upload key cannot be rotated without Google's help.

---

## Releasing

1. Bump the version in **both** places — they must agree or the release
   workflow fails on purpose:
   - `pubspec.yaml` → `version: 1.4.0+6`
   - `android/local.properties` → `flutter.versionName=1.4.0`,
     `flutter.versionCode=6`
   The `+N` is **Android's** `versionCode`: one counter for the life of the
   app, never reset, always higher than anything Play has accepted.
   `bundle exec fastlane current_version` prints what that is.

   iOS does not use it. Its build number only has to rise within a marketing
   version, so `ios/fastlane/Fastfile` asks App Store Connect what it already
   holds for this version and adds one — a new version name starts at 1.
   Override with `IOS_BUILD_NUMBER` if a build has to be replaced.
2. Regenerate audio if any word changed:
   `python3 scripts/generate_word_audio.py --force`
3. PR `dev` → `main`, merge when green. That builds, signs, and uploads to
   **TestFlight and the Play internal track**. Nothing is submitted to review.
4. Install the build and try it on a real device.
5. Actions → **promote** → **Run workflow**. This promotes the Play internal
   build to production at 20%, submits the TestFlight build for App Store
   review, and only then stamps `docs/version.json` — which is what prompts
   existing users to update.
6. Raise the Play rollout from 20% once the crash rate looks clean. In App
   Store Connect, press **Release this version** when Apple approves.

Neither promote job rebuilds. It ships the binary that was tested.

### What does not trigger a build

`release.yml` ignores pushes that only touch `docs/**`, any `.md`, `.github/**`
or `LICENSE`. Editing the site or the press kit is not a release, and on
Android it could not be one anyway — the versionCode has not moved, so Play
would reject the upload.

If a release ever needs to go out and the only change is in one of those
paths, run it by hand: **Actions → release → Run workflow**.

---

## Worth adding later

- **Integration tests in CI.** `reactivecircus/android-emulator-runner` boots an
  emulator on a GitHub runner. Slow, but it would have caught the silent-audio
  bug that unit tests can't see.
- **Golden tests for the stroke paths.** Render each letter to a PNG and diff
  against a checked-in reference. The Malayalam and Hindi paths were corrected
  dozens of times by eye, and coverage-against-the-skeleton is a poor proxy —
  it is meaningless for letters deliberately redrawn or for constructed loops.
  A golden test turns "does this still look right?" into a pass/fail.
- **A screenshot lane.** Fastlane's `capture_screenshots` can regenerate the
  press-kit images on every release, so `docs/press/` stops drifting behind the
  app.
- **Dependabot** for `pubspec.yaml` and the Actions themselves.
