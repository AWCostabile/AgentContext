"""What every extractor shares: the normalised fact set, a lexer for brace and paren
depth, the doc-comment summary sentence and the scrubbing that keeps values out of a leaf.

An extractor returns, per source file, one dict built by new_facts():

  language     the extractor's name
  package      the file's package or module name where the language has one, else None
  module_doc   the file's own doc summary sentence, '' when none
  symbols      [{name, kind, line, exported, parent, signature, summary}] in source order;
               `parent` names the enclosing type of a member, None at top level;
               `signature` is the declaration head with string literals scrubbed, '' when
               the kind has none
  imports      [{source, line}] module specifiers, never resolved
  exports      [{name, line, source, local}] names exported other than by a declaration
               (a re-export or an export list); `source` the module re-exported from, or
               None; `local` the name it is exported from when it is renamed, or None
  env          [{name, line}] environment variable NAMES read, never their values
  entry        [{kind, line}] reasons this file is an entry point
  notes        [str] what the extractor could not read in this file
  error        str | None: the file could not be read at all
"""
import re

ELLIPSIS = chr(0x2026)
BOM = chr(0xFEFF)
SUMMARY_CAP = 160
SIGNATURE_CAP = 120
ABBREVIATIONS = ('e.g', 'i.e', 'etc', 'vs', 'cf')   # a period after these never ends a sentence


def new_facts(language):
    return {'language': language, 'package': None, 'module_doc': '', 'symbols': [], 'imports': [],
            'exports': [], 'env': [], 'entry': [], 'notes': [], 'error': None}


def read_source(path):
    """The file's text with a BOM dropped and line ends normalised to LF.

    Raises OSError when unreadable and UnicodeDecodeError when it is not UTF-8."""
    with open(path, 'rb') as f:
        data = f.read()
    text = data.decode('utf-8')
    if text.startswith(BOM):
        text = text[1:]
    return text.replace('\r\n', '\n').replace('\r', '\n')


# --- the lexer -----------------------------------------------------------------------------

class LineState:
    """The lexer's state at the start of one line."""
    __slots__ = ('brace', 'paren', 'inside')

    def __init__(self, brace, paren, inside):
        self.brace, self.paren, self.inside = brace, paren, inside


REGEX_PRECEDERS = set('(,=:[!&|?{;+-*%>~^')
REGEX_KEYWORDS = ('return', 'typeof', 'case', 'do', 'else', 'in', 'of', 'new', 'delete', 'void', 'throw', 'yield', 'await')


def line_states(text, flavour):
    """One LineState per line of `text`, plus whether the text ended balanced.

    `flavour` is 'ts' (template literals with `${}` nesting, regex literals) or 'go' (raw
    backtick strings, runes). `inside` is true when the line starts inside a comment or a
    string, so its column 0 is not code. Brackets count with parentheses."""
    states = []
    brace = paren = 0
    mode = 'code'           # code | block | sq | dq | tmpl | raw | regex
    resume = []             # brace depths at which a template literal resumes (ts)
    prev = ''               # the last significant code character
    word = ''               # the identifier that ended at `prev`
    in_class = False        # inside a regex character class
    n = len(text)
    i = 0
    states.append(LineState(0, 0, False))
    while i < n:
        c = text[i]
        if c == '\n':
            if mode in ('sq', 'dq', 'regex'):
                mode = 'code'           # an unterminated single-line literal ends at the line
            states.append(LineState(brace, paren, mode != 'code'))
            i += 1
            continue
        if mode == 'block':
            if text.startswith('*/', i):
                mode = 'code'
                i += 2
                continue
            i += 1
            continue
        if mode in ('sq', 'dq'):
            if c == '\\':
                i += 2
                continue
            if (c == "'" and mode == 'sq') or (c == '"' and mode == 'dq'):
                mode = 'code'
                prev, word = c, ''
            i += 1
            continue
        if mode == 'raw':
            if c == '`':
                mode = 'code'
                prev, word = c, ''
            i += 1
            continue
        if mode == 'tmpl':
            if c == '\\':
                i += 2
                continue
            if c == '`':
                mode = 'code'
                prev, word = c, ''
            elif text.startswith('${', i):
                resume.append(brace)
                brace += 1
                mode = 'code'
                prev, word = '{', ''
                i += 2
                continue
            i += 1
            continue
        if mode == 'regex':
            if c == '\\':
                i += 2
                continue
            if c == '[':
                in_class = True
            elif c == ']':
                in_class = False
            elif c == '/' and not in_class:
                mode = 'code'
                prev, word = 'a', ''
            i += 1
            continue
        # code
        if text.startswith('//', i):
            j = text.find('\n', i)
            i = n if j < 0 else j
            continue
        if text.startswith('/*', i):
            mode = 'block'
            i += 2
            continue
        if c == "'":
            mode = 'sq'
        elif c == '"':
            mode = 'dq'
        elif c == '`':
            mode = 'tmpl' if flavour == 'ts' else 'raw'
        elif c == '/' and flavour == 'ts' and (prev == '' or prev in REGEX_PRECEDERS or word in REGEX_KEYWORDS):
            mode = 'regex'
            in_class = False
        elif c == '{':
            brace += 1
        elif c == '}':
            if resume and resume[-1] == brace - 1:
                resume.pop()
                brace -= 1
                mode = 'tmpl'
                i += 1
                continue
            brace -= 1
        elif c in '([':
            paren += 1
        elif c in ')]':
            paren -= 1
        if c.isalnum() or c in '_$':
            j = i
            while j < n and (text[j].isalnum() or text[j] in '_$'):
                j += 1
            word, prev = text[i:j], 'a'
            i = j
            continue
        if not c.isspace():
            prev, word = c, ''
        i += 1
    balanced = brace == 0 and paren == 0 and mode in ('code', 'sq', 'dq', 'regex')
    return states, balanced


# --- doc comments and summaries ----------------------------------------------------------

def clean_block_doc(raw):
    """A /** … */ block's lines without the delimiters or each line's leading `*`."""
    body = raw[3:-2] if raw.endswith('*/') else raw[3:]
    return [re.sub(r'^\s*\*\s?', '', l).strip() for l in body.split('\n')]


def _sentence_end(text):
    """Index just past the first sentence terminator (and its closers), or None."""
    in_code = False
    for i, c in enumerate(text):
        if c == '`':
            in_code = not in_code
            continue
        if in_code or c not in '.?!':
            continue
        if c == '.' and ((i > 0 and text[i - 1] == '.') or (i + 1 < len(text) and text[i + 1] == '.')):
            continue                                     # a run of periods never ends a sentence
        j = i + 1
        while j < len(text) and text[j] in '"\')]':
            j += 1
        if j < len(text) and not text[j].isspace():
            continue
        if c == '.':
            m = re.search(r'([A-Za-z.]+)$', text[:i])
            if m and m.group(1).lower() in ABBREVIATIONS:
                continue
        return j
    return None


def _title_key(text):
    return re.sub(r'[\s_-]+', '', text.lower())


def _is_title(line, names):
    """True when `line`, less a trailing parenthetical, only names one of `names`."""
    t = re.sub(r'\s*\([^()]*\)\s*$', '', line).strip().rstrip('.:')
    return bool(t) and any(_title_key(t) == _title_key(n) for n in names if n)


def summary_of(lines, names=()):
    """The summary sentence of a cleaned doc block, shared by every extractor.

    The description only (it stops at the first `@` tag line); its first paragraph, skipping
    a one-line paragraph that only names the documented thing; the first sentence of it,
    cut after a terminator outside a code span; capped at SUMMARY_CAP characters at a word
    boundary with a trailing ellipsis, never inside a code span. No description gives ''."""
    desc = []
    for l in lines or []:
        t = l.strip()
        if t.startswith('@'):
            break
        desc.append(t)
    paras, cur = [], []
    for t in desc + ['']:
        if t:
            cur.append(t)
        elif cur:
            paras.append(cur)
            cur = []
    para = None
    for p in paras:
        if len(p) == 1 and _is_title(p[0], names):
            continue
        para = p
        break
    if not para:
        return ''
    text = ' '.join(para)
    end = _sentence_end(text)
    if end is not None:
        text = text[:end]
    if len(text) <= SUMMARY_CAP:
        return text
    cut = max((m.start() for m in re.finditer(r'\s', text[:SUMMARY_CAP])), default=SUMMARY_CAP - 1)
    head = text[:cut]
    if head.count('`') % 2:
        head = head[:head.rfind('`')]
    return head.rstrip() + ELLIPSIS


# --- keeping values out ------------------------------------------------------------------

STRING_RE = re.compile(r'"(?:[^"\\\n]|\\.)*"|\'(?:[^\'\\\n]|\\.)*\'|`[^`]*`')


def scrub(text):
    """A declaration head with every string literal's content replaced by an ellipsis,
    whitespace collapsed, and capped at SIGNATURE_CAP characters."""
    s = STRING_RE.sub(lambda m: m.group(0)[0] + ELLIPSIS + m.group(0)[0], text)
    s = re.sub(r'\s+', ' ', s).strip()
    if len(s) > SIGNATURE_CAP:
        s = s[:SIGNATURE_CAP - 1].rstrip() + ELLIPSIS
    return s
