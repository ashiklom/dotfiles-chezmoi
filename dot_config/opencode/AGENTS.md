When writing prose in plain-text formats (txt, md, etc.), prefer semantic line breaks: write one sentence or complete logical idea per line. This ensures version control diffs are structural and logical rather than purely formatting-driven. This relies on standard Markdown behavior where single line breaks render as a single continuous paragraph.

Example:

```markdown
The dog jumped over the fence.
The fence was rather tall, so this was quite a feat.
Other things the dog did today include:
eating breakfast;
running and playing in the yard;
and
taking a snooze on the couch.
```

Avoid hard wrapping to a specific line width unless that style is already used in the file (in which case, follow the existing style).
