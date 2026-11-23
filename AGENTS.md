# .github

Org defaults for `revtriever-vera`: issue and PR templates, the profile README, the working contract and the skills.

- `skills/<group>/<name>/` is the source of every skill; `skills/sync-config.json` maps groups to repos.
- Running Sync Skills (manual, `workflow_dispatch`) copies each group to `.claude/skills/` in its repos and
  prunes the rest.
- `contract/CONTRACT.md` is the working contract every agent loads. The same sync writes it as a
  marked block at the top of each repo's `AGENTS.md`: change it here, never inside the block.
  `contract/inject.sh <target> [contract]` does the writing and can be run by hand.
- A copy in another repo's `.claude/skills/` is a mirror: change the skill here, and leave the copy
  to the sync.
- This repo is public: nothing sensitive goes in the tree, issues, PRs or commits (see the `conventions` skill).
- A PR here changes how every agent works: the maintainer merges it.
