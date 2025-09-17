# Useful debugging commands

| Command                                                     | Purpose                                                                                                                   |
| ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `deno info _config.ts`                                      | Inspect dependencies for a file                                                                                           |
| `deno task lume upgrade --version v2.5.3`                   | Upgrade lume to a specific version                                                                                        |
| `gh act -W .github/workflows/release-site.yml --pull=false` | Run github action locally - requires [gh CLI](https://cli.github.com/) and [act plugin](https://github.com/nektos/gh-act) |
