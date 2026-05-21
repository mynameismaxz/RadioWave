# Contributing

Thanks for improving RadioWave. Keep changes focused, tested, and easy to
review.

## Development Workflow

1. Create a branch from `main`.
2. Make a focused change.
3. Run local checks.
4. Open a pull request with a clear summary and test notes.

```powershell
.\tool\flutter.cmd pub get
.\tool\flutter.cmd analyze
.\tool\flutter.cmd test
```

For UI, audio, Android Auto, or platform changes, also build the affected target:

```powershell
.\tool\flutter.cmd build apk --debug
.\tool\flutter.cmd build web --release
```

## Commit Style

Use concise conventional commits:

```text
feat: add Android Auto browse roots
fix: prevent now playing overflow on automotive displays
ci: add APK artifact workflow
docs: document release process
```

## Pull Request Checklist

- The change is scoped to one problem.
- `flutter analyze` passes.
- Tests pass or the reason they cannot run is documented.
- UI changes include a screenshot or short visual note.
- Release-facing changes update `README.md` or `docs/` when needed.

## Security

Do not commit secrets, keystores, signing passwords, API tokens, or local
environment files. Use GitHub Actions secrets for deployment credentials.
