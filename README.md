# nixpkg-automated-plan-reviser-pro

Thin Nix packaging repo for [`Dicklesworthstone/automated_plan_reviser_pro`](https://github.com/Dicklesworthstone/automated_plan_reviser_pro).

## Upstream

- Repo: `Dicklesworthstone/automated_plan_reviser_pro`
- Vendored source: [`upstream/`](/home/rona/Repositories/@nixpkgs/nixpkg-automated-plan-reviser-pro/upstream)
- Upstream script version: `1.2.2`
- Vendored commit: `edd6bd19af61d78651e2e2ccb73be5ee7f226294`

## Usage

```bash
nix build
nix run
```

The package exposes the `apr` binary and wraps it with the runtime tools it expects on `PATH`, including `nodejs` so APR can use `npx @steipete/oracle`.

`apr update` is not expected to self-mutate a Nix-installed binary; refresh [`upstream/`](/home/rona/Repositories/@nixpkgs/nixpkg-automated-plan-reviser-pro/upstream) and rebuild instead.
