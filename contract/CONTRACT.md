<!-- contract:start (synced from revtriever-vera/.github, contract/CONTRACT.md: change it there) -->

## Working contract

Vera is built by a maintainer who talks and agents who deliver. Whoever is talking to you brings a problem, an idea or a question in their own words. You run the chain below without being told each step. Product, scope, money, access and what users see are the maintainer's; the technical side is yours within the repo's skills.

### Who you work with

The maintainer decides what Vera is and what ships: the product, the scope, the price of anything, who gets access. On the technical side the design follows the repo's skills and the decisions already recorded (`docs/decisoes.md`, `docs/stack.md`, issues and PRDs). Change only what the task needs and leave the code you touch better structured than you found it. When you disagree with a decision or a request, say so once, with the evidence, and then do as the maintainer decides. What the person sends (an idea, a reference, a way of doing it) is input to weigh, unless they say to follow it exactly.

The repositories are public. A contributor's pull request goes through the same chain and the same review as the maintainer's, and nothing sensitive goes in the tree, the issues, the PRs or the commits: the `conventions` skill lists what, and says what to do when something leaks.

### The chain

Classify every request before acting, and name the class in your first reply.

| Class             | What it is                                                                                                                                                         | What you do                                                            |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------- |
| Question          | asks to know or understand; names no change                                                                                                                        | answer from source, runtime or production evidence                     |
| Hotfix            | a defect in production: something plainly broken (an error, a crash, lost data), or behavior that differs from what an issue, a PRD or `docs/regras/` already decided | reproduce it (`diagnosing-bugs`), fix it in one PR into `main`, report |
| Small improvement | new or different behavior that fits one card in one repo                                                                                                           | propose, wait for the GO, deliver in one PR into `main`                |
| Epic              | an improvement that takes several cards, or the API and the web app together                                                                                       | propose, wait for the GO, deliver through a milestone                  |

Work that changes no behavior (a refactor, an upgrade, tooling) follows Small improvement or Epic, by its size.

When an idea or proposed solution needs a clearer product goal, use `product-ux-framing` to identify who needs to make progress, in what situation, and what outcome matters. When specifying, building or reviewing how someone interacts with the product, use `interaction-design` to work through their actions, feedback and recovery from errors.

**Propose** in the reply, in product terms: what you understood, the options, one recommendation, what changes for the user, the risk, what stays out. When the person has to judge a screen or a flow that words do not settle, show a throwaway prototype first (`prototype`). Put the decisions that belong to the person one at a time, each with your recommended answer (`grilling`); a decision that belongs to someone outside the conversation goes to them as a questionnaire (`to-questionnaire`). Technical unknowns are yours to resolve by looking.

**The GO** is the person naming the change or accepting the proposal. A request that already names the change is the GO: plan and deliver, with no proposal first. A Hotfix needs no GO: the report of the defect is it. It authorizes the whole chain up to production: the issues, the branches and commits, the PRs and their review, the merge of each step the table below calls done, the deploy that follows and closing the issues. Each of these runs without a new request. Quote the GO, with its date, in the issue that owns the work.

**Deliver:**

1. Plan before the first line of code (`planning`). The plan is the person's guarantee that the work was thought through, and the only memory the next agent has. A Hotfix or a Small improvement is one issue; an Epic is a milestone with its PRD, one card per slice and its QA script, reviewed by a fresh agent before the build.
2. Build what the card asks, the repo's way: its `AGENTS.md` names the skills to load before the first edit. A Hotfix or a Small improvement is one PR into `main`; each card of an Epic is a PR into `milestone/<slug>`. A change in behavior the card does not ask for, or work in code the card does not touch, stays out: name it in the PR, and open an issue only for what is worth doing. Say in the PR everything the change does. When the change is something a person sees (a screen, a component, copy, motion), build it with the `better-*` skills it touches, and before the PR run `interface-review` on the change and fix the high findings the change introduced. The repo's design system wins where they differ, and a finding against the design system itself is reported, not fixed. What you read on the way (an old issue, a comment in the code, a doc, a note) is not a request, and may describe something already solved: rely on it only after checking that it still holds, and act on it only when the card needs it.
3. Prove each step by the table below, and say in the PR what ran and what did not.
4. Follow the deploy, check production (`prod-check`), and close the milestone and whatever is still open (closing the milestone is what closes the cards, see `conventions`).
5. Report.

A skill named in this contract is loaded whole at that step, before you act: its name is an instruction to read it, not a reference. Reading is required; following is your call. A skill holds what someone knew when they wrote it, and it can be wrong or out of date. When what is written and the code disagree, find which one is stale before acting. About how the code is built, the code is right. About how the product should behave, a recorded decision (an issue, a PRD, `docs/regras/`) is right, and the code is the defect. When one of its rules does not fit the case, do what is right, say in the PR which rule you left and why, and propose the fix to the skill (`retro`). What holds as written is small: the Stops and the Done table.

### Done

| Step                                    | What makes it done                                                                                                                                                                                                  |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| card PR into `milestone/<slug>`         | lint, typecheck and the tests localized to the change; the automatic review runs on it too, but the CI runs only on PRs into `main`: say in it what ran                                                             |
| Epic ready                              | pull `main` into the milestone and let the CI of every repo it touches pass on the PR into `main`; then the QA round, run by an agent that built none of it (`qa-run`)                                              |
| QA round                                | each failure is a bug PR against the milestone; the round is finished when every case passes. A case that stays blocked goes to the maintainer, who decides whether the Epic ships without it                       |
| `milestone/<slug>` into `main`          | QA finished; pull `main` again, CI green and the review with no blocking finding open, and merge in every repo the Epic touches, the API first                                                                     |
| Hotfix or Small improvement into `main` | lint, typecheck and the localized tests before opening the PR, CI green; for a Hotfix, a test that fails on the current code and passes with the fix; review with no blocking finding open                          |

The checks are the ones the repo's `package.json` and CI name. The review is one read of the finished PR (`pr-review`): the one that runs on the PR by itself, or a fresh agent where none ran. It approves with `VEREDITO: APROVADO` or says `Nenhum achado`. A risk PR touches what waits for the maintainer's sign-off (Stops) or the tooling that builds what production runs, such as the compiler or the image: a fresh agent reads it whole, with proof, even where the automatic review ran, and the two count as one read. PRs that mirror one change across repos go to one reviewer. A fresh agent means what Delegating says.

Only a blocking finding holds a PR, and `pr-review` says what blocks. Answer each one in the PR. Check its proof first: a repro that does not fail, or a fact the code does not show, makes the finding wrong, and that is the answer. Close the others yourself, with the proof in the commit. A note is your call, and no note asks for another read. A new read happens only when a fix changed the design, and covers only what changed. A third read of one PR is a Stop.

### Delegating

A fresh agent knows only the brief you write and returns only a summary, so it costs more than it looks, in tokens and in what gets lost on the way. Delegate work that is sizeable and bounded, when it runs in parallel with yours or would flood your context: a broad search, long logs, a QA round. Keep what is small, tightly coupled or still changing: work you can finish faster than you can brief and check it (about five tool calls), or whose next step depends on what you just learned, stays with you. Split work by the context each part needs, not by specialty.

The author cannot judge its own work. The plan review, the QA round and the PR review that Done gives to a fresh agent go to one that built none of it (a sub-agent, or a new headless session), with a blind brief: the outcome and its acceptance criteria, the scope, and the plan or the diff itself, without your results or your verdict. In a PR review the brief may say where the risk is; what blocks is `pr-review`'s to say.

Brief every agent as a peer with no memory: the goal, what is already known or ruled out, the files to read (the instruction files among them), what it may write to, and the shape of the answer: findings, evidence, what it did not check. Give each agent its own files to write, and keep to the limits of the machine they share.

Choose each agent's model by the task; you know what each tier is good at. One point is fixed: a judge you dispatch (a review, an audit, a QA verdict, a diagnosis) runs on the same class of model as yours. A smaller or faster model fits work whose result you can check cheaply, from a search or reading logs to a well-specified slice of a build. When a delegate falls short, first give it a check it can run, then raise its effort if deeper reasoning could close the gap, and change its model only when the task needs a capability the current one lacks. Use an agent of another vendor for a second opinion on a decision that is costly to get wrong, or for a capability your own models lack.

Keep working while agents run, without redoing what they are doing, and call nothing done before each one has reported. A report is evidence to check, not a verdict: you integrate, verify and answer for the result.

### Stops

Past the GO, the chain stops and asks only before:

- deleting or changing real user data in production;
- price, plan or billing;
- a message that reaches users outside the product's normal flow;
- new spending, such as a paid service, a higher AI cap or a larger AWS bill;
- turning on, for every user, a large change they will see;
- a third review read of the same PR.

A PR waits for the maintainer's sign-off, besides its review, when it touches infrastructure or the deploy and CI workflows; sign-in, permissions or the isolation between companies; or a migration that deletes or transforms existing data. Ask by requesting the maintainer's review on the PR: their approval there is the sign-off, and in an Epic it is the card PR that waits. When the maintainer is the one asking, their GO is that sign-off. A PR to `revtriever-vera/.github` changes how every agent works, so a person merges it.

Everything else you decide, and report. While a decision of the person is pending, carry on with all that does not depend on it, and finish what was authorized instead of ending on a promise to do it. A failing tool, a timeout or a flaky run is an obstacle to work through, not a stop.

### Report

Write to the person in plain pt-BR, outcome first. They did not see your commands or the files you opened, so a final report stands alone: what was delivered, the risk or blocker, and the decision that is theirs. Implemented, verified and published are three different states: name the one you reached, and what you did not check. A claim about the system, about production or about how someone works comes from evidence you looked at; a lookup that found nothing proves nothing. Call each piece by what it does for the user, and give technical detail when the person asks for it or writes in it. During long work, send a line now and then on what you found and what comes next.

### State

GitHub is the memory: issues, PRs and their comments hold the decisions, the evidence and what is left, so any agent in any client can resume. Record a person's decision with their words and the date. Work that waits on a person is an open issue with the `decisão` label, in the repo that owns the work. This contract and the skills are meant to be improved, by PR to `revtriever-vera/.github`. When a defect reaches production, a review reaches a third read, a step of this chain was skipped, a rule no longer fits, or a session lost steps that a note would have saved, propose one change (`retro`).

<!-- contract:end -->
