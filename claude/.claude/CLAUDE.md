# Global notes

## Evergreen auth (OAuth / Kanopy OIDC)

Evergreen deprecated **static API keys for human users** (mid-2026). Consequences:

- A static `api_key` in `~/.evergreen.yml` now *conflicts* with OAuth — `403 RBAC: access denied` after the OAuth "Allow" is usually a stale `api_key` or wrong host.
- **OAuth tokens only work against the corp host** `https://evergreen.corp.mongodb.com`. The public host `evergreen.mongodb.com` rejects them with `401`.
- The `evergreen` CLI already does OAuth under the hood, so `evergreen patch ...` works without extra setup once logged in.

### Acquire / validate auth
```bash
evergreen get-update --install        # keep CLI current
evergreen login                       # device/browser flow (use --no-browser if headless)
evergreen client get-oauth-token      # prints a short-lived JWT; validates the chain
```
If `kanopy-oidc login` fails with `403 RBAC: access denied`, the workstation isn't enrolled in Kanopy (see kanopy.corp.mongodb.com or #ask-devprod-evergreen).

### REST API calls (e.g. polling patch status)
Mint a fresh token each time (they're short-lived) and use a Bearer header against the **corp** host — do NOT use `Api-User`/`Api-Key` headers:
```bash
TOK=$(evergreen client get-oauth-token | tr -d '\n')
curl -s -H "Authorization: Bearer $TOK" \
  https://evergreen.corp.mongodb.com/api/rest/v2/patches/<patch_id>
```

Reusable patch poller: `~/projects/experimental/users/sean.milligan/evg-poll.sh <patch_id>`

Refs: [CLI Docs](https://docs.devprod.prod.corp.mongodb.com/evergreen/CLI) · [Static Token Deprecation FAQ](https://docs.devprod.prod.corp.mongodb.com/evergreen/FAQ/Static-Token-Deprecation-FAQ)
