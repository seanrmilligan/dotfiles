# CLAUDE.md

## JSON handling

- Use `jq` for anything that parses, filters, or validates JSON. Do not use
  `python3 -c` or `python3 -m json.tool`. Assume `jq` is installed and raise a
  concern when you find it is not, rather than falling back to some other tool.
