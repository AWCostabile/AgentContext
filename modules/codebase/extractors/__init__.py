"""The extractor registry: one entry per language, by name, with the file patterns it claims.

An extractor is a module exposing NAME, LANGUAGE, PATTERNS (fnmatch patterns over a file's
basename), DEFAULT (whether it runs when no --lang is given), and
`extract(root, rel) -> facts` (the fact set in common.py). It may also expose EXCLUDE
(patterns it never claims), `identity(root, files) -> (lines, notes)` and
`entries(root, files) -> [{name, kind, path, line}]` for repository-level facts.

A file no selected extractor claims is listed under "Not extracted", never handed to an
extractor for another language. Adding a language is one module and one line below.
"""
import fnmatch

from . import typescript

EXTRACTORS = {}


def register(module, name=None, default=None, patterns=None, exclude=None):
    """Register `module` under `name` (default its NAME), optionally overriding its patterns."""
    entry = {
        'name': name or module.NAME,
        'module': module,
        'language': module.LANGUAGE,
        'patterns': tuple(patterns if patterns is not None else module.PATTERNS),
        'exclude': tuple(exclude if exclude is not None else getattr(module, 'EXCLUDE', ())),
        'default': module.DEFAULT if default is None else default,
    }
    EXTRACTORS[entry['name']] = entry


register(typescript)


def claims(entry, rel):
    """True when the extractor entry claims the repository-relative path `rel`."""
    base = rel.rsplit('/', 1)[-1]
    if any(fnmatch.fnmatchcase(base, p) for p in entry['exclude']):
        return False
    return any(fnmatch.fnmatchcase(base, p) for p in entry['patterns'])


def claimant(rel, names=None):
    """The first registered extractor claiming `rel`, among `names` when given."""
    for name, entry in EXTRACTORS.items():
        if (names is None or name in names) and claims(entry, rel):
            return entry
    return None
