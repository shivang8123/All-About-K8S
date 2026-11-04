# Contributing

Thanks for helping make Kubernetes errors less scary.

## Ways to contribute
- Fix a wrong or unclear explanation
- Add a missing cause, diagnostic command or fix to an existing error
- Add a new error (see the format below)
- Add a broken example manifest under `examples/`

## Format for an error entry
Each error in `docs/` follows the same structure:

1. `## NN. ErrorName` heading
2. **In plain English**: one sentence
3. **Common causes**: short bullet list
4. **How to diagnose**: `kubectl` commands in a `bash` block
5. **How to fix**: numbered steps
6. **Reproduce it**: link to an example manifest, if one exists

## Guidelines
- Keep wording simple and beginner friendly
- Test every command and manifest on a real or local cluster (kind or minikube)
- Warn clearly before risky commands (force delete, patching finalizers)
- Open an issue first for large changes

## Pull requests
1. Fork the repo and create a branch: `git checkout -b fix/oomkilled-docs`
2. Make your change and keep the PR focused on one topic
3. Describe what you changed and how you verified it
