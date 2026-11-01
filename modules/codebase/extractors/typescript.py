"""The TypeScript and JavaScript extractor: a line parser over the top-level grammar.

It reads, at brace depth 0: functions, classes, interfaces, types, enums, namespaces and
`const`/`let`/`var` declarations, exported or not; `import` statements and top-level
`require()` calls; `export { … }` lists and re-exports; and, one level into a class or
interface body, its members (a `private` or `#` member is not listed). A declaration's
summary is the first sentence of the `/** … */` block directly above it. It never resolves
an import and never evaluates anything.

It does not see: a second name in a multi-name declaration (`const a = 1, b = 2` lists `a`),
a destructured declaration, members declared by assignment in a constructor, or a
declaration produced by a call. A file whose braces do not balance is noted.
"""
import json
import os
import re

from .common import (ELLIPSIS, clean_block_doc, line_states, new_facts, read_source, scrub,
                     summary_of)

NAME = 'typescript'
LANGUAGE = 'TypeScript/JavaScript'
PATTERNS = ('*.ts', '*.tsx', '*.mts', '*.cts', '*.js', '*.jsx', '*.mjs', '*.cjs')
DEFAULT = True

IDENT = r'[A-Za-z_$][\w$]*'
DECL = re.compile(r'^(export\s+)?(default\s+)?(declare\s+)?(async\s+)?'
                  r'(function\b\s*\*?|abstract\s+class\b|class\b|interface\b|type\b|const\s+enum\b|enum\b'
                  r'|namespace\b|module\b|const\b|let\b|var\b)\s*(' + IDENT + r')?')
DEFAULT_EXPR = re.compile(r'^export\s+default\s+(' + IDENT + r')?\s*(;|$|\()?')
EXPORT_LIST = re.compile(r'^export\s+(type\s+)?\{')
EXPORT_STAR = re.compile(r'^export\s+\*\s*(?:as\s+(' + IDENT + r'))?\s*from\s*([\'"])([^\'"]+)\2')
IMPORT_FROM = re.compile(r'\bfrom\s*([\'"])([^\'"]+)\1')
IMPORT_BARE = re.compile(r'^import\s*([\'"])([^\'"]+)\1')
IMPORT_EQ = re.compile(r'^import\s+' + IDENT + r'\s*=\s*require\(\s*([\'"])([^\'"]+)\1')
REQUIRE = re.compile(r'\brequire\(\s*([\'"])([^\'"]+)\1\s*\)')
FUNC_VALUE = re.compile(r'^\s*(?::[^=]+)?=\s*(async\s+)?(function\b|\(|' + IDENT + r'\s*=>|<)')
MODIFIERS = r'(?:(?:public|protected|private|static|readonly|abstract|override|declare|async|accessor)\s+)*'
MEMBER = re.compile(r'^\s*(' + MODIFIERS + r')(get\s+|set\s+)?(\*\s*)?(#?' + IDENT + r')\s*([?!])?\s*(\(|<|:|=|;|$)')
NOT_MEMBERS = ('return', 'if', 'for', 'while', 'switch', 'const', 'let', 'var', 'case', 'default', 'throw')
ENV_PATTERNS = (re.compile(r'process\.env\.(' + IDENT + r')'),
                re.compile(r'process\.env\[\s*[\'"]([^\'"]+)[\'"]\s*\]'),
                re.compile(r'import\.meta\.env\.(' + IDENT + r')'))
KINDS = {'abstract class': 'class', 'const enum': 'enum', 'module': 'namespace', 'function*': 'function'}


def doc_above(lines, i):
    """The cleaned /** block ending directly above line i, decorator lines skipped."""
    j = i - 1
    while j >= 0 and lines[j].lstrip().startswith('@'):
        j -= 1
    if j < 0 or not lines[j].rstrip().endswith('*/'):
        return None
    end = j
    while j >= 0:
        k = lines[j].find('/*')
        if k >= 0 and (j < end or k < lines[j].rfind('*/')):
            head = lines[j][k:]
            if head.startswith('/**') and not head.startswith('/**/'):
                return clean_block_doc('\n'.join([head] + lines[j + 1:end + 1]).rstrip())
            return None
        j -= 1
    return None


def module_doc(lines):
    """The first column-0 /** block followed by a blank line or an import."""
    i = 1 if lines and lines[0].startswith('#!') else 0
    while i < len(lines):
        if lines[i].startswith('/**') and not lines[i].startswith('/**/'):
            j = i
            while j < len(lines) and '*/' not in (lines[j][3:] if j == i else lines[j]):
                j += 1
            end = min(j, len(lines) - 1)
            nxt = lines[end + 1] if end + 1 < len(lines) else ''
            if not nxt.strip() or nxt.startswith('import'):
                return clean_block_doc('\n'.join(lines[i:end + 1]).strip())
            return None
        if lines[i].strip() and not lines[i].startswith('//'):
            return None
        i += 1
    return None


def head_until_body(text):
    """`text` up to the `{` or `=>` that opens a body at parenthesis depth 0, and whether
    the head closed on this line."""
    depth = 0
    for i, c in enumerate(text):
        if c in '([':
            depth += 1
        elif c in ')]':
            depth -= 1
        elif depth == 0 and (c == '{' or text.startswith('=>', i)):
            return text[:i].rstrip(), True
    return text.rstrip(), depth <= 0


def signature_of(rest):
    """A callable's parameters and return type, from the text that follows its name."""
    head, closed = head_until_body(rest)
    sig = scrub(head.rstrip(';').rstrip())
    return sig if closed else sig + ' ' + ELLIPSIS


def arrow_signature(rest):
    """The parameters and return type of a `name = (…) => …` initialiser."""
    m = re.match(r'^\s*(?::[^=]+)?=\s*(?:async\s+)?(?:function\b\s*\*?\s*)?', rest)
    return signature_of(rest[m.end():]) if m else ''


def split_names(body):
    """`a, b as c, type d` -> [(local, exported)]."""
    out = []
    for part in body.split(','):
        part = re.sub(r'^\s*type\s+', '', part.strip())
        m = re.match(r'^(' + IDENT + r')(?:\s+as\s+(' + IDENT + r'))?$', part)
        if m:
            out.append((m.group(1), m.group(2) or m.group(1)))
    return out


def joined(lines, i, done, limit=40):
    """Lines from i joined with spaces until `done(text)` holds; None past `limit` lines.
    Nothing is consumed: the lines after i sit inside braces, which the walk skips."""
    parts = []
    for j in range(i, min(len(lines), i + limit)):
        parts.append(lines[j].strip())
        text = ' '.join(parts)
        if done(text):
            return text
    return None


def extract(root, rel):
    facts = new_facts(NAME)
    try:
        text = read_source(os.path.join(root, rel))
    except (OSError, UnicodeDecodeError) as e:
        facts['error'] = 'not readable as UTF-8 text (%s)' % type(e).__name__
        return facts
    lines = text.split('\n')
    states, balanced = line_states(text, 'ts')
    if not balanced:
        facts['notes'].append('its braces or parentheses do not balance, so its declarations may be incomplete')
    if lines and lines[0].startswith('#!'):
        facts['entry'].append({'kind': 'executable script', 'line': 1})
    facts['module_doc'] = summary_of(module_doc(lines), [os.path.splitext(os.path.basename(rel))[0]])

    symbols, local_exports = facts['symbols'], []
    owner = None            # (name, exported, kind) of the class or interface whose body is open
    for i, line in enumerate(lines):
        st = states[i]
        if st.inside:
            continue
        if st.brace == 1 and st.paren == 0 and owner:
            member(lines, i, owner, symbols)
            continue
        if st.brace != 0 or st.paren != 0:
            continue
        s = line.strip()
        if s == '{' and owner:
            continue                                       # a body brace on a line of its own
        owner = None
        if s.startswith('import'):
            read_import(lines, i, facts)
            continue
        if EXPORT_LIST.match(s):
            read_export_list(lines, i, facts, local_exports)
            continue
        m = EXPORT_STAR.match(s)
        if m:
            facts['exports'].append({'name': m.group(1) or '*', 'line': i + 1, 'source': m.group(3), 'local': None})
            facts['imports'].append({'source': m.group(3), 'line': i + 1})
            continue
        for r in REQUIRE.finditer(s):
            facts['imports'].append({'source': r.group(2), 'line': i + 1})
        m = DECL.match(s)
        if m and (m.group(6) or m.group(2)):
            raw = re.sub(r'\s+', ' ', m.group(5)).strip().replace(' *', '*')
            kind = KINDS.get(raw, raw)
            name = m.group(6) or 'default'
            rest = s[m.end():]
            sig = ''
            if kind == 'function':
                sig = signature_of(rest)
            elif kind in ('const', 'let', 'var') and FUNC_VALUE.match(rest):
                kind, sig = 'function', arrow_signature(rest)
            symbols.append({'name': name, 'kind': kind, 'line': i + 1, 'exported': bool(m.group(1)),
                            'parent': None, 'signature': sig,
                            'summary': summary_of(doc_above(lines, i), [name])})
            if kind in ('class', 'interface'):
                owner = (name, bool(m.group(1)), kind)
            continue
        m = DEFAULT_EXPR.match(s)
        if m:
            name = m.group(1) if m.group(1) and m.group(2) in (';', '') else 'default'
            symbols.append({'name': name, 'kind': 'default export', 'line': i + 1, 'exported': True,
                            'parent': None, 'signature': '', 'summary': summary_of(doc_above(lines, i), [name])})

    # an export list marks a local declaration exported, or records the name it exports
    top = {}
    for sym in symbols:
        if sym['parent'] is None:
            top.setdefault(sym['name'], sym)
    for local, exported, line in local_exports:
        sym = top.get(local)
        if sym is not None and local == exported:
            for s in symbols:
                if s is sym or s['parent'] == local:
                    s['exported'] = True
        else:
            facts['exports'].append({'name': exported, 'line': line, 'source': None,
                                     'local': local if sym is not None else None})

    for n, line in enumerate(lines):
        if states[n].inside or line.lstrip().startswith('//'):
            continue
        for rx in ENV_PATTERNS:
            for m in rx.finditer(line):
                facts['env'].append({'name': m.group(1), 'line': n + 1})
    return facts


def member(lines, i, owner, symbols):
    """One line one level into a class or interface body, read as a member if it is one."""
    s = lines[i]
    t = s.strip()
    if not t or t.startswith(('//', '/*', '*', '@', '[', '(', '}', '<')):
        return
    m = MEMBER.match(s)
    if not m:
        return
    mods, accessor, name, opener = m.group(1).split(), m.group(2), m.group(4), m.group(6)
    if name.startswith('#') or 'private' in mods or name in NOT_MEMBERS:
        return
    after = s[m.start(6):]
    if accessor:
        kind = 'accessor'
    elif name == 'constructor':
        kind = 'constructor'
    elif opener in ('(', '<') or (owner[2] == 'class' and opener == '=' and FUNC_VALUE.match(after)):
        kind = 'method'
    else:
        kind = 'property'
    sig = ''
    if kind in ('method', 'constructor'):
        sig = signature_of(after) if opener in ('(', '<') else arrow_signature(after)
    symbols.append({'name': name, 'kind': kind, 'line': i + 1, 'exported': owner[1], 'parent': owner[0],
                    'signature': sig, 'summary': summary_of(doc_above(lines, i), [name])})


def read_import(lines, i, facts):
    if re.match(r'^import\s*\(', lines[i].strip()):        # a dynamic import expression
        return

    def spec(t):
        return IMPORT_EQ.match(t) or IMPORT_FROM.search(t) or IMPORT_BARE.match(t)

    stmt = joined(lines, i, spec, limit=400)
    if stmt is None:
        facts['notes'].append('the import at line %d was not read' % (i + 1))
        return
    facts['imports'].append({'source': spec(stmt).group(2), 'line': i + 1})


def read_export_list(lines, i, facts, local_exports):
    stmt = joined(lines, i, lambda t: '}' in t)
    if stmt is None:
        facts['notes'].append('the export list at line %d was not read' % (i + 1))
        return
    body = stmt[stmt.find('{') + 1:]
    close = body.find('}')
    tail = body[close + 1:]
    if not tail.strip():                                  # `} \n from '…'`
        more = joined(lines, i, lambda t: '}' in t and bool(IMPORT_FROM.search(t[t.find('}'):])), limit=41)
        tail = more[more.find('}'):] if more else ''
    names = split_names(body[:close])
    m = IMPORT_FROM.search(tail)
    if m:
        facts['imports'].append({'source': m.group(2), 'line': i + 1})
        for local, exported in names:
            facts['exports'].append({'name': exported, 'line': i + 1, 'source': m.group(2),
                                     'local': None if local == exported else local})
    else:
        local_exports.extend((local, exported, i + 1) for local, exported in names)


# --- repository-level facts --------------------------------------------------------------

def _package(root):
    path = os.path.join(root, 'package.json')
    if not os.path.isfile(path):
        return None, None
    try:
        return json.loads(read_source(path)), None
    except (OSError, UnicodeDecodeError, ValueError) as e:
        return None, 'the root `package.json` could not be read (%s)' % type(e).__name__


def identity(root, files):
    """Identity lines for the code map: the root package's name, never its scripts' values."""
    pkg, err = _package(root)
    if err:
        return [], [err]
    if not isinstance(pkg, dict) or not isinstance(pkg.get('name'), str):
        return [], []
    return [('Package', pkg['name'])], []


def entries(root, files):
    """Entry points the root package.json names: main, module, bin, and each script that
    runs a source file, by the script's name and never its command."""
    pkg, _ = _package(root)
    if not isinstance(pkg, dict):
        return []
    fileset = set(files)
    out = []

    def add(name, kind, target):
        t = str(target).replace('\\', '/')
        while t.startswith('./'):
            t = t[2:]
        if t in fileset:
            out.append({'name': name, 'kind': kind, 'path': t, 'line': None})

    for key in ('main', 'module'):
        if isinstance(pkg.get(key), str):
            add(key, 'package.json ' + key, pkg[key])
    bins = pkg.get('bin')
    if isinstance(bins, str):
        bins = {str(pkg.get('name', 'bin')): bins}
    if isinstance(bins, dict):
        for k in sorted(bins):
            add(k, 'package.json bin', bins[k])
    scripts = pkg.get('scripts')
    if isinstance(scripts, dict):
        for k in sorted(scripts):
            for tok in re.findall(r'"[^"]*"|\'[^\']*\'|\S+', str(scripts[k])):
                add(k, 'package.json script', tok.strip('"\''))
    return out
