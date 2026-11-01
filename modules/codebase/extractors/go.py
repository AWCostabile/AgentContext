"""The Go extractor: a line parser over Go's top-level grammar.

Go's top level is closed: `package`, `import`, `func`, `type`, `const` and `var`, each
alone or as a parenthesised group. This parser reads every one of them: the package name
and its doc comment; import paths; functions, and methods under their receiver's type;
types, with a struct's fields and an interface's methods; and the NAMES of constants and
variables, never their values. A summary is the first sentence of the `//` comment block
directly above a declaration. A column-0 line outside the grammar is noted, never guessed
at. A struct tag is never emitted.
"""
import os
import re

from .common import ELLIPSIS, line_states, new_facts, read_source, scrub, summary_of

NAME = 'go'
LANGUAGE = 'Go'
PATTERNS = ('*.go',)
EXCLUDE = ('*_test.go',)
DEFAULT = True

IDENT = r'[A-Za-z_][A-Za-z0-9_]*'
PACKAGE = re.compile(r'^package\s+(' + IDENT + r')')
IMPORT_ONE = re.compile(r'^import\s+(?:(' + IDENT + r'|\.|_)\s+)?"([^"]+)"')
IMPORT_SPEC = re.compile(r'^\s*(?:(' + IDENT + r'|\.|_)\s+)?"([^"]+)"')
GROUP = re.compile(r'^(import|const|var|type)\s*\(')
FUNC = re.compile(r'^func\s+(' + IDENT + r')')
METHOD = re.compile(r'^func\s*\(\s*(?:' + IDENT + r'\s+)?\*?\s*(' + IDENT + r')\s*(?:\[[^\]]*\])?\s*\)\s*(' + IDENT + r')')
TYPE_ONE = re.compile(r'^type\s+(' + IDENT + r')')
TYPE_SPEC = re.compile(r'^\s*(' + IDENT + r')(\s*\[[^\]]*\])?\s+(=\s*)?(\S.*)$')
VALUE_ONE = re.compile(r'^(const|var)\s+(' + IDENT + r'(?:\s*,\s*' + IDENT + r')*)')
VALUE_SPEC = re.compile(r'^\s*(' + IDENT + r'(?:\s*,\s*' + IDENT + r')*)(?=\s|=|$)')
FIELD = re.compile(r'^\s*(' + IDENT + r'(?:\s*,\s*' + IDENT + r')*)\s+([^`/]+?)\s*(?:`.*)?(?://.*)?$')
EMBEDDED = re.compile(r'^\s*(\*?' + IDENT + r'(?:\.' + IDENT + r')?(?:\[[^\]]*\])?)\s*(?:`.*)?(?://.*)?$')
IFACE_METHOD = re.compile(r'^\s*(' + IDENT + r')\s*(\(.*)$')
ENV = re.compile(r'\b(?:os|syscall)\.(?:Getenv|LookupEnv)\(\s*"([^"]+)"\s*\)')
DIRECTIVE = re.compile(r'^//[a-z]+:\S')


def comment_above(lines, i):
    """The `//` lines directly above line i, directives dropped, as cleaned doc lines."""
    out = []
    j = i - 1
    while j >= 0 and lines[j].lstrip().startswith('//'):
        t = lines[j].strip()
        if not DIRECTIVE.match(t):
            out.append(re.sub(r'^//\s?', '', t))
        j -= 1
    return list(reversed(out)) or None


def exported(name):
    return name[:1].isupper()


def signature_from(text):
    """Parameters and results: the text up to the body's `{` at parenthesis depth 0."""
    depth = 0
    for i, c in enumerate(text):
        if c in '([':
            depth += 1
        elif c in ')]':
            depth -= 1
        elif c == '{' and depth == 0:
            return scrub(text[:i])
    s = scrub(text)
    return s if depth <= 0 else s + ' ' + ELLIPSIS


def strip_comment(s):
    k = s.find('//')
    return s if k < 0 else s[:k]


def extract(root, rel):
    facts = new_facts(NAME)
    try:
        text = read_source(os.path.join(root, rel))
    except (OSError, UnicodeDecodeError) as e:
        facts['error'] = 'not readable as UTF-8 text (%s)' % type(e).__name__
        return facts
    lines = text.split('\n')
    states, balanced = line_states(text, 'go')
    if not balanced:
        facts['notes'].append('its braces or parentheses do not balance, so its declarations may be incomplete')
    symbols = facts['symbols']
    group = None            # 'import' | 'const' | 'var' | 'type' while a parenthesised group is open
    owner = None            # (type name, 'struct' | 'interface', paren depth of its body's lines)
    unknown = []

    def add(name, kind, line, parent=None, signature=''):
        doc = comment_above(lines, line - 1)
        public = exported(name.rsplit('.', 1)[-1])          # an embedded field is named by its type
        symbols.append({'name': name, 'kind': kind, 'line': line, 'exported': public, 'parent': parent,
                        'signature': signature, 'summary': summary_of(doc, [name])})

    def open_type(name, rest, line, depth):
        nonlocal owner
        body = re.match(r'^(struct|interface)\s*\{\s*(?://.*)?$', rest.strip())
        if re.match(r'^(struct|interface)\s*\{', rest.strip()):
            add(name, rest.strip().split()[0].split('{')[0], line)
        else:
            add(name, 'type', line, signature=scrub(strip_comment(rest)))
        owner = (name, body.group(1), depth) if body else None

    for i, raw in enumerate(lines):
        st = states[i]
        n = i + 1
        if st.inside:
            continue
        s = raw.strip()
        if owner and st.brace == 1 and st.paren == owner[2]:
            if s and not s.startswith(('//', '/*', '}')):
                read_member(s, n, owner, add)
            continue
        if st.brace != 0:
            continue
        if group and st.paren == 1:
            if not s or s.startswith(('//', '/*', ')')):
                continue
            if group == 'import':
                m = IMPORT_SPEC.match(s)
                if m:
                    facts['imports'].append({'source': m.group(2), 'line': n})
            elif group == 'type':
                m = TYPE_SPEC.match(s)
                if m:
                    open_type(m.group(1), m.group(4) if not m.group(3) else '= ' + m.group(4), n, 1)
            else:
                m = VALUE_SPEC.match(s)
                if m:
                    for name in re.split(r'\s*,\s*', m.group(1)):
                        add(name, group, n)
            continue
        if st.paren != 0:
            continue
        group = None
        owner = None
        if not s or s.startswith(('//', '/*', '}', ')')):
            continue
        m = PACKAGE.match(s)
        if m:
            facts['package'] = m.group(1)
            facts['module_doc'] = summary_of(comment_above(lines, i), ['package ' + m.group(1), m.group(1)])
            continue
        m = GROUP.match(s)
        if m:
            group = m.group(1)
            continue
        m = IMPORT_ONE.match(s)
        if m:
            facts['imports'].append({'source': m.group(2), 'line': n})
            continue
        m = METHOD.match(s)
        if m:
            add(m.group(2), 'method', n, parent=m.group(1), signature=signature_from(s[m.end():]))
            continue
        m = FUNC.match(s)
        if m:
            add(m.group(1), 'function', n, signature=signature_from(s[m.end():]))
            if m.group(1) == 'main' and facts['package'] == 'main':
                facts['entry'].append({'kind': 'Go main package', 'line': n})
            continue
        m = TYPE_ONE.match(s)
        if m:
            rest = s[m.end():]
            gm = re.match(r'^(\s*\[[^\]]*\])?\s*(=\s*)?(.*)$', rest)
            open_type(m.group(1), ('= ' if gm.group(2) else '') + gm.group(3), n, 0)
            continue
        m = VALUE_ONE.match(s)
        if m:
            for name in re.split(r'\s*,\s*', m.group(2)):
                add(name, m.group(1), n)
            continue
        unknown.append((n, s))
    if unknown:
        facts['notes'].append('%d top-level line(s) are outside the grammar the parser reads (first at line %d)'
                              % (len(unknown), unknown[0][0]))

    for n, line in enumerate(lines):
        if states[n].inside or line.lstrip().startswith('//'):
            continue
        for m in ENV.finditer(line):
            facts['env'].append({'name': m.group(1), 'line': n + 1})
    return facts


def read_member(s, n, owner, add):
    """One line of a struct or interface body: a field, an embedded type, or a method."""
    name, shape = owner[0], owner[1]
    if shape == 'interface':
        m = IFACE_METHOD.match(s)
        if m:
            add(m.group(1), 'method', n, parent=name, signature=signature_from(strip_comment(m.group(2))))
            return
        m = EMBEDDED.match(s)
        if m:
            add(m.group(1).lstrip('*'), 'embedded', n, parent=name)
        return
    m = FIELD.match(s)
    if m and not m.group(2).strip().startswith('`'):
        for field in re.split(r'\s*,\s*', m.group(1)):
            add(field, 'field', n, parent=name, signature=scrub(m.group(2)))
        return
    m = EMBEDDED.match(s)
    if m:
        add(m.group(1).lstrip('*'), 'embedded', n, parent=name)


# --- repository-level facts --------------------------------------------------------------

def identity(root, files):
    """The module path go.mod declares, as an identity line."""
    path = os.path.join(root, 'go.mod')
    if 'go.mod' not in files or not os.path.isfile(path):
        return [], []
    try:
        for line in read_source(path).split('\n'):
            m = re.match(r'^module\s+(\S+)', line)
            if m:
                return [('Go module', m.group(1).strip('"'))], []
    except (OSError, UnicodeDecodeError) as e:
        return [], ['`go.mod` could not be read (%s)' % type(e).__name__]
    return [], []
