# API Contract Template

Copy into `docs/plan/contracts/<feature>.<openapi.yaml|graphql|proto>` — the **standalone,
versioned, frozen** source of truth both the backend (provider) and frontend (consumer) build
against. See `coordinating-api-contract` for the freeze/change/conformance discipline.

Pick the block matching the repo's paradigm (from `designing-an-api`). Fill every `<…>`; leave no
placeholder. It must be complete enough to **generate a mock** and **validate a response** — every
in-scope operation, request/response schema, the shared error envelope, status codes, and
per-operation auth.

Keep the **version + changelog header** — it is what makes a change detectable and a re-sync
explicit under the change protocol.

---

## Option A — REST (OpenAPI 3.1, YAML)

```yaml
# Contract: <feature>
# Version: 0.1.0        # bump on every change; note it below
# Changelog:
#   0.1.0 — initial frozen contract
openapi: 3.1.0
info:
  title: <Feature> API
  version: 0.1.0
servers:
  - url: <base path, e.g. /api/v1>
paths:
  /<resource>:
    get:
      operationId: list<Resource>
      summary: <what it does>
      security: [{ <scheme>: [] }]        # per-operation auth — state it, don't hand-wave
      parameters:
        - { name: <cursor>, in: query, schema: { type: string }, required: false }
      responses:
        "200":
          description: <success>
          content:
            application/json:
              schema: { $ref: "#/components/schemas/<Resource>List" }
        "401": { $ref: "#/components/responses/Error" }
        "403": { $ref: "#/components/responses/Error" }
    post:
      operationId: create<Resource>
      security: [{ <scheme>: [] }]
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: "#/components/schemas/<Resource>Create" }
      responses:
        "201":
          content:
            application/json:
              schema: { $ref: "#/components/schemas/<Resource>" }
        "400": { $ref: "#/components/responses/Error" }   # validation
        "401": { $ref: "#/components/responses/Error" }
        "409": { $ref: "#/components/responses/Error" }
components:
  securitySchemes:
    <scheme>: { type: http, scheme: bearer }
  responses:
    Error:                                   # ONE consistent error envelope, reused everywhere
      description: Error
      content:
        application/json:
          schema: { $ref: "#/components/schemas/Error" }
  schemas:
    Error:
      type: object
      required: [code, message]
      properties:
        code: { type: string, description: stable machine code }
        message: { type: string }
        details: { type: array, items: { type: object } }
    <Resource>:
      type: object
      required: [<id>, <field>]
      properties:
        <id>: { type: string }
        <field>: { type: <type> }
    <Resource>Create:
      type: object
      required: [<field>]
      properties:
        <field>: { type: <type> }
    <Resource>List:
      type: object
      required: [items]
      properties:
        items: { type: array, items: { $ref: "#/components/schemas/<Resource>" } }
        nextCursor: { type: string, nullable: true }
```

## Option B — GraphQL (SDL)

```graphql
# Contract: <feature>  | Version: 0.1.0
# Changelog: 0.1.0 — initial frozen contract

type <Resource> {
  <id>: ID!
  <field>: <Type>!
}

input Create<Resource>Input {
  <field>: <Type>!
}

type <Resource>Connection {
  items: [<Resource>!]!
  nextCursor: String
}

# Consistent error handling: prefer typed error results over throwing where the repo does.
type Query {
  <resource>(id: ID!): <Resource>          # @auth(<scope>) — state per-field authorization
  <resources>(cursor: String): <Resource>Connection!
}
type Mutation {
  create<Resource>(input: Create<Resource>Input!): <Resource>!
}
```

## Option C — gRPC (proto3)

```proto
// Contract: <feature>  | Version: 0.1.0
// Changelog: 0.1.0 — initial frozen contract
syntax = "proto3";
package <feature>.v1;

service <Resource>Service {
  rpc Get<Resource>(Get<Resource>Request) returns (<Resource>);      // auth: <policy>
  rpc Create<Resource>(Create<Resource>Request) returns (<Resource>);
}

message <Resource> {
  string <id> = 1;
  <type> <field> = 2;
}
message Get<Resource>Request { string <id> = 1; }
message Create<Resource>Request { <type> <field> = 1; }
// Errors: use google.rpc.Status codes consistently across the service.
```

---

## Freeze note

Once this artifact is approved at the design gate it is **frozen**: the backend and frontend
plans, code, and conformance tests all cite it as read-only truth. To change it, run the
**contract-change protocol** in `coordinating-api-contract` — edit here, bump the version, note
the changelog, re-approve, and re-sync both sides. Never change a shape in code without moving the
artifact first.
