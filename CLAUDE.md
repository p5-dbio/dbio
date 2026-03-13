# CLAUDE.md -- DBIO Core

## Core-Specific Build

Uses `[@DBIO] core = 1` which enables: VersionFromMainModule (version from `$VERSION` in lib/DBIO.pm), MakeMaker::Awesome, ExecDir, extra GatherDir excludes, no GithubMeta.

Has additional plugins beyond `[@DBIO]`: MetaNoIndex, MetaResources.

## dist.ini specifics

```ini
copyright_holder = DBIO Contributors
copyright_year = 2005
```
