<!--
  Rule template: one leaf of a product's code-rules catalog, a branch beside its `design/`
  made from this template directory, stored beside that branch's `.index.md` and paired with
  a Contents row there. A catalog leaf may hold SEVERAL rules: group them by the area or the
  bug class they guard, and repeat the `## {{rule-id}}` section once per rule. Every rule
  carries all five parts below, so an agent triaging a hit reads the false-positive shapes
  instead of re-deriving them. An id is unique within the catalog and never reused.
  Replace every `{{ }}` and remove this comment.
-->

# {{Product Name}} rules: {{area or bug class}}

{{One line: what the rules in this leaf guard against.}}

## {{rule-id}}: {{the rule, in one sentence}}

- **Source:** {{the design leaf, wiki section or repository instruction this rule enforces}}
- **Detection:** {{a pattern (the regex, and the files it runs over) · a structural check · judgement}}
- **Tier:** {{hard: a script alone decides and a hit blocks · suspect: a script flags and an agent confirms or clears · judgement: only a reading agent finds it}}
- **False-positive shapes:** {{the shapes a legitimate hit takes, each with how to recognise it; an idiom the product already uses to say the same thing is named here}}
- **Dismissal:** {{a comment beside the line, in the language's own comment syntax: `allow {{rule-id}}: <reason>`; a sweep's false positive is also a `cleared` row in the findings ledger, with its reason}}
