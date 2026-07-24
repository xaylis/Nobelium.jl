---
name: Payload parse error
about: '"X is missing required field Y" or another failure parsing something Discord sent'
labels: [bug, parsing]
---

**The error** (tokens are auto-redacted in errors, but double-check before pasting)

```
```

**What triggered it** (the command you ran, the event that fired, ...)

**Link to the Discord docs for the payload, if you know it**

Discord sends partial objects in several places (interaction resolved data,
audit logs, ...), and a field our types require may be optional there — that
class of bug is quick to fix if the error names the type and field.

**Environment**
- Nobelium version:
- Julia version:
