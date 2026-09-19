# ACM-Extended
A massive overhaul to ACM.

## Branches and release builds

- `main` is the public 1.2.2 release source. The experimental drag handle has been removed; standard ACE dragging and carrying remain available.
- `dev` retains the experimental drag handle for further work. Use `main` when preparing the public release.

Run these commands in PowerShell from your repository folder:

```powershell
git switch main
if ($LASTEXITCODE -ne 0) { throw 'Could not switch to main.' }
git pull --ff-only origin main
if ($LASTEXITCODE -ne 0) { throw 'Pull failed.' }
hemtt release
if ($LASTEXITCODE -ne 0) { throw 'HEMTT release failed.' }
```

## Patch notes

- [Cumulative 1.2.2 patch notes](CHANGELOG.md)
- [Discord posts and detailed patch records](docs/patch-notes/README.md)
