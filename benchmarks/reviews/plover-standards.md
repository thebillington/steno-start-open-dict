# Plover standards checked for the open decisions

Date: 2026-10-29

These references are external documentation, not dictionary input. They were
used only to decide whether a rule is community-accepted.

## Asterisk use

Sources:

- Plover Wiki, Theory: <https://plover.wiki/index.php/Theory>
- Learn Plover, Lesson 10: Designing Briefs:
  <https://opensteno.org/learn-plover/lesson-9-designing-briefs.html>
- Learn Plover, Appendix: Cheat Sheet:
  <https://opensteno.org/learn-plover/appendix-cheat-sheet.html>
- Plover Practice, Multistroke Words:
  <https://practiceplover.com/multistroke-words>

What they say:

- Homophones commonly use the plain form for the more common word and the
  asterisk for the less common word.
- The asterisk is also a general briefing and disambiguation tool. Learn Plover
  says that when a brief is already taken, "maybe adding the * key will produce
  a stroke that's not yet in the dictionary file."
- The Plover default dictionary uses the "less common word gets asterisk"
  method for conflicts, not only strict homophones.
- Plover Practice says one stroke is better than two if possible, and that
  writers may pack syllables into one stroke.

Conclusion: non-homophone asterisk collisions such as `certain S*ERPBT`,
`corner KO*RPB`, `cross KRO*S` and `away WA*EU` are consistent with general
Plover practice. They are kept and documented. This is not a claim that they
are in Plover's default dictionary.

## Coda packing

Sources:

- Plover Theory, Chorded Keyboard:
  <https://morinted.gitbooks.io/plover-theory/content/layout/chorded-keyboard.html>
- Learn Plover, Lesson 2: Steno Order:
  <https://opensteno.org/learn-plover/lesson-2-steno-order.html>
- Learn Plover, Appendix: Cheat Sheet:
  <https://opensteno.org/learn-plover/appendix-cheat-sheet.html>

What they say:

- Keys are always processed in the fixed steno order.
- A word can be one stroke when its sounds fit steno order.
- Unstressed vowels can be dropped to make a word fit.
- The cheat sheet allows two neighbouring sounds to invert steno order, but only
  once in a word.
- If the sounds do not fit, the word is written with multiple strokes.

Conclusion: single-chord packing is accepted only while it fits those rules.
The generator currently records multi-phone codas but does not prove that every
packed coda has at most one neighbouring inversion. This is a known source
standard gap, not an arbitrary style choice. Fixing it needs a coda validator
and a multi-stroke fallback, which was not applied in this round.

## Other decisions

The `-le` elision, authored `ER` row, `use` verb sense, current published
alternatives and `four TPAOR` were kept by explicit decision. They remain
documented as authored Steno Start choices.
