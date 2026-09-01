# Expose the Right MCP Tools

Business Central 28 can act as an MCP server: an AI agent connects to it, asks what tools are available, and calls them. Which tools exist is entirely up to an **MCP server configuration** — you list API pages and, per page, say whether the agent may read, create, modify, delete or invoke bound actions. Get that list wrong in the generous direction and an agent can delete production data because a prompt asked it nicely.

Your app already ships three API pages for its agent. What it lacks is the setup code: something an install or upgrade codeunit can call on every run to put the configuration in place, exactly once, granting nothing more than the agent needs. Business Central manages MCP configurations from AL through the public System Application codeunit `"MCP Config"` — everything below goes through it.

## Requirements

The starter contains three finished API pages. Keep them in your submission unchanged and add one codeunit of your own.

| API page | What the agent is allowed to do with it |
|---|---|
| `"TryAL Agent Customer API"` | read only |
| `"TryAL Agent Item API"` | read only |
| `"TryAL Agent Contact API"` | read, create, modify, bound actions — but never delete |

Create a **codeunit** named `"MCP Tool Surface"` with two public procedures:

```al
procedure EnsureConfiguration(): Guid
procedure RepairConfiguration(ConfigId: Guid): Integer
```

`EnsureConfiguration` builds the surface and returns the configuration's id (the `SystemId` GUID of the configuration record):

1. The configuration is named exactly `TryAL Agent Surface` — that spelling, spaces and capitals included, is what agents connect with. Its description is yours to choose and is not graded.
2. It exposes exactly three tools, one per API page in the table above, and nothing else — no fourth tool, no query tool.
3. Each tool carries exactly the permissions its row grants and no others: for the two lookup pages, read is allowed and create, modify, delete and bound actions are all denied; for the contact page, read, create, modify and bound actions are allowed and delete is denied.
4. Dynamic tool mode stays off, and so does discovery of read-only objects that are not in the configuration — the agent sees these three tools and nothing else in the environment.
5. When the procedure returns, the configuration is active.
6. Calling it a second time changes nothing: it must find the existing configuration by name, return the **same** GUID it returned the first time, and leave its tools alone. Installing or upgrading the app twice must not produce a second configuration or a duplicated tool.

`RepairConfiguration` cleans up a configuration that has drifted — someone edited it by hand, or a tool ended up in a state Business Central considers wrong:

7. It asks Business Central for the warnings raised against the configuration with the given id, applies the recommended action to every one of them, and returns how many warnings it acted on.
8. A configuration that Business Central raises no warnings for is left untouched and yields 0.
9. It grants nothing beyond what the recommended actions themselves change — repairing a configuration must never widen a tool's permissions on its own.

Pick object IDs in the house range 50100–50199, and reference other objects by name, never by literal ID. Captions and tooltips are not graded.

## What the tests check

The grading tests call `EnsureConfiguration` and then read the configuration back through Business Central's own JSON export, checking tool by tool: exactly three tools, each pointing at one of the three API pages as a page tool, and each of the five permission flags (`allowRead`, `allowCreate`, `allowModify`, `allowDelete`, `allowBoundActions`) matching the table above exactly — a tool that is granted one flag too many fails. They check that the name `TryAL Agent Surface` resolves back to the id you returned, that dynamic tool mode and read-only object discovery are both off, and that the finished configuration is active (an inactive configuration cannot be designated the default one, which is how the test observes it). Two tests call `EnsureConfiguration` twice and require the same GUID and still exactly three tools. Another test asserts that Business Central reports no warnings at all for the configuration you built. The repair tests switch a write-enabled tool's read permission off behind your back — once for one tool, once for two — and expect `RepairConfiguration` to return the matching count, to leave no warnings behind, and to restore read access on the contact tool without turning delete on; a healthy configuration must yield 0. One of them also switches read off on a lookup tool at the same time — a state Business Central raises no warning about — and requires that tool to come out of the repair exactly as it went in, read still off: a tool the platform does not complain about keeps its permissions untouched.

## Learn More

- [Model Context Protocol (MCP) in Business Central overview](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/ai/mcp-overview) — what an MCP server exposes and why tool permissions are a security boundary.
- [Configure Business Central MCP Server](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/ai/configure-mcp-server) — the configuration fields and per-tool permissions this task builds from AL, and how each allowed operation becomes an agent tool.
- [API page type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-api-pagetype) — what makes the starter's pages eligible to be exposed as tools.
- [Walkthrough: developing a custom API](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-develop-custom-api) — the API page properties the starter uses, if you want the background.
