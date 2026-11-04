# In-repository layout

This source suite lives alongside top-level `review-code/` and `review-pr/` skills.
The canonical editor inputs are `src/shared/*.md` and `src/review-*.md`.
From this checkout, `python3 review-toolkit/tools/build_skills.py` generates
`review-code/SKILL.md` and `review-pr/SKILL.md` at repository root.
Do not hand-edit generated `SKILL.md` files.

`python3 review-toolkit/install.py install --target all --with-reviewer --dry-run` previews deployment.
`python3 review-toolkit/install.py upgrade --target all --with-reviewer` upgrades installed skills.

`python3 review-toolkit/tools/make_distributor.py` builds a fully standalone
archive and installer in the checkout root. Generated nested skills are added
to that archive only, avoiding duplicate skill names in this repository.
