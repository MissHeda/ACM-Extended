# ACM Extended patch notes

The [cumulative 1.2.2 notes](../../CHANGELOG.md) combine all subsequent patches from 18–19 September 2026 through commit [8fd12c0](https://github.com/hesherson/ACM-Extended/commit/8fd12c016f17504b05781925f095d75f0fbe9424).

Version 1.2.2 includes the release check corrections and the complete RC1 patch series and updates the public, debug and build versions. Public releases use `main`, which excludes the experimental drag handle. The handle remains on `dev` for further work. Use the cumulative notes for current behavior. The dated records below retain the implementation history and validation details; later corrections supersede earlier descriptions, particularly seizure speed/startup and the subsequent removal of the drag handle from the public release.

## Discord copy

Each file below is one complete post under 4,000 characters. Copy the contents of each file as a separate message, in order. The @everyone mention appears in the first post.

- [Post 1 of 3](1.2.2-discord-1.txt) (3,618 characters)
- [Post 2 of 3](1.2.2-discord-2.txt) (1,937 characters)
- [Post 3 of 3](1.2.2-discord-3.txt) (3,877 characters)

The latest medication duration followup passed 25 focused checks on this branch. See the [input patch record](2026-09-19-push-duration-input.md) for scope and the remaining in-game checks.

## Discord format

Use this announcement format for release notes. Do not use em dashes or unnecessary hyphenation. Preserve exact version strings, technical identifiers, URLs and Markdown list markers. Keep section headings uppercase, include the repair reminder and documentation footer, and split long announcements into posts below 4,000 characters. Use the release's actual version in the title. Place @everyone in the first post of a multipart announcement.

```text
@everyone

# ACM Extended v{version} - Hotfix

:exclamation~1:Remember to repair your mod:exclamation~1:

## GENERAL FIXES

- {Change}

-# **[See documentation here](https://hesherson.github.io/ACM-Extended-Wiki/index.html)**
```

## Individual patch records

- [Medication push duration input](2026-09-19-push-duration-input.md)

- [Transfusion and thoracostomy](2026-09-19-transfusion-thoracostomy.md)
- [Patient motion and ketamine](2026-09-19-patient-motion.md)
- [Chest interactions, drag rope and held auscultation](2026-09-19-chest-interactions.md)
- [Final seizure speed correction, posterior auscultation and clinical descriptors](2026-09-19-auscultation-seizures.md)
- [PEA morphology](2026-09-19-pea-morphology.md)
- [Release check corrections](2026-09-19-release-warnings.md)
- [Release drag handle removal](2026-09-19-release-drag-removal.md)

The current release source passed 31 focused tests, including strict HEMTT checks and config compilation. Pull `main` and rebuild to remove the drag handle, then verify gameplay in Arma. The earlier Windows release predates this removal. See the validation section in the main notes and the detailed checks in each patch record.
