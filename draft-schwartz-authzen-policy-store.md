---
stand_alone: true
ipr: none
cat: std
submissiontype: IETF
wg: OpenID AuthZEN

docname: draft-schwartz-authzen-policy-store

title: AuthZEN Policy Store Format
abbrev: policy-store
lang: en
kw:
 - Authorization
 - Policy Store
 - PDP
 - AuthZEN
 - CJAR

author:
- role: editor
  ins: M. Schwartz
  name: Michael Schwartz
  org: Gluu
  email: mike@gluu.org
- role: editor
  ins: D. Desai
  name: Dhaval Desai
  org: Gluu
  email: dhaval@gluu.org

contributor:
- name: Victor Moreno
  org: Independent Contributor
  email: victor.moreno@gmail.com

normative:
 RFC8259:
 RFC7519:
 RFC8615:
 RFC2119:

informative:
 CEDAR:
   title: Cedar Policy Language
   target: https://docs.cedarpolicy.com/
   author:
   - name: Cedar Team
     org: Amazon Web Services
 CERBOS:
   title: Cerbos Policy Decision Point
   target: https://docs.cerbos.dev/
   author:
   - name: Cerbos Project
     org: Cerbos
 AUTHZEN-API:
   title: Authorization API 1.0
   target: https://openid.net/specs/authorization-api-1_0.html
   author:
   - name: OpenID AuthZEN Working Group
     org: OpenID Foundation

--- abstract

This document defines the AuthZEN Policy Store Format and an API for managing policy stores. A policy store is a Policy Decision Point (PDP) neutral packaging format for co-locating authorization policies, schema, default entities, trusted token issuers, and related metadata required for evaluation. The format supports a directory structure for development and version control, and a compressed archive format (`.cjar`, Constraint JAR) for distribution and deployment. Policy stores packaged in this format improve interoperability among PDPs, tooling, and the OpenID AuthZEN ecosystem regardless of underlying policy language or engine. PDP also serves the policy store API that allows administrators to upload the updated versions of the policy store. API does not allow updates to an existing store or deletion of the same.

--- middle

# Introduction

Policy Decision Points (PDPs) evaluate authorization requests using policies, schema, and supporting configuration. PDP implementations — including engines such as Cedar ({{CEDAR}}) and Cerbos ({{CERBOS}}) — do not today share a common way to package and version those artifacts together. In practice, policies are written against a specific schema and evaluated with a consistent set of default entities and trusted token issuers. Without a standard packaging format, organizations adopt ad hoc conventions, which impedes portability, auditability, and interoperability among PDPs and third-party tools.

The OpenID AuthZEN Working Group defines protocols and patterns for authorization interoperability, including the Authorization API ({{AUTHZEN-API}}). This specification complements AuthZEN by defining policy store API and a portable, PDP neutral, self-contained **policy store** format that any conforming PDP or tool MAY load, validate, and exchange without proprietary layout conventions.

This document defines version 1.0 of the AuthZEN Policy Store Format.

# Conventions and Definitions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in BCP 14 ({{RFC2119}}) when, and only when, they appear in all capitals, as shown here.

## Terminology

Policy Store:
: A structured collection of policies, schema, and related artifacts bound together for evaluation, as defined in this document.

Policy Engine:
: The policy language and evaluation implementation used by a PDP (for example, Cedar or Cerbos). Identified in `metadata.json` by `policy_engine` and `policy_engine_version`.

Directory Format:
: A policy store represented as a folder hierarchy on a filesystem.

Archive Format:
: A policy store packaged as a ZIP archive with the `.cjar` file extension.

Constraint JAR (CJAR):
: The Archive Format; a ZIP archive whose extension `.cjar` denotes a **constraint jar** — a self-contained package of authorization constraints (policies, schema, and related configuration) for distribution and deployment.

Policy Decision Point (PDP):
: A component that evaluates authorization requests against policies. See {{AUTHZEN-API}}.

# Overview

## Policy store API

The **`/policystore`** endpoint is a POST‑only HTTP API that accepts a **`.cjar`** (Constraint JAR) file containing a policy store. This API enables PDP administrators to upload the updated versions of the policy stores. API does not expose HTTP methods that allow updates or deletion of the existing policy stores. This ensures that the policy stores are treated as immutable stores and can be versioned and rolled back easily.

## Policy store

A **policy store** bundles together the artifacts that a PDP needs to evaluate authorization requests against a known schema and configuration baseline. These artifacts include:

* Policy engine declaration in `metadata.json`
* Policies (one policy document per file under `policies/`)
* Optional schema (`schema/`)
* Optional policy templates (`templates/`)
* Optional default entities (`entities/`)
* Optional trusted issuer configuration (`trusted-issuers/`)
* Required metadata (`metadata.json`)

The syntax and semantics of policy documents, schema files, and entity types are defined by the declared **policy engine**. This specification defines the container layout, metadata, and interchange formats only.

Implementations MAY support either the Directory Format or the Archive Format, or both. Tools that produce or consume policy stores SHOULD support conversion between formats without loss of content.

The Archive Format is a ZIP archive containing the same relative paths as the Directory Format. Archive files MUST use the `.cjar` extension.

# Policy Store API

Policy store API defines `/policystore` endpoint for uploading the policy store.

## API Request

The **`/policystore`** endpoint is a POST‑only HTTP API that accepts a **`.cjar`** (Constraint JAR) file containing a policy store. The request body must be a multipart/form‑data upload with the following parts:

- **file**: The `.cjar` archive.
- **metadata**: A JSON object providing:
  - `version` (string): The version of the policy store.
  - `created_timestamp` (string, ISO‑8601): The creation date‑time of the uploaded policy store.

**Example Request**:

~~~http
POST /policystore HTTP/1.1
Host: api.example.com
Content-Type: multipart/form-data; boundary=---XYZ

-----XYZ
Content-Disposition: form-data; name="file"; filename="store.cjar"
Content-Type: application/zip

<binary .cjar content>
-----XYZ
Content-Disposition: form-data; name="metadata"
Content-Type: application/json

{"version":"1.0.0","created_timestamp":"2026-07-15T10:30:00Z"}
-----XYZ--
~~~

## API Response

The server validates the uploaded file and metadata. On success it stores the file and returns **201 Created** with a JSON body containing the assigned identifier. On validation failure it returns **400 Bad Request** with an error description.

**Example Response (Success)**:

~~~json
{
  "id": "store-12345",
  "message": "Policy store uploaded successfully."
}
~~~

**Example Response (Error)**:

~~~json
{
  "error": "Invalid metadata.version does not match archive."
}
~~~

# Policy Store Directory Structure

The root of a policy store (directory or archive) is referred to as the **policy store root**. The following layout is REQUIRED for conformant policy stores:

~~~ ascii-art
policy-store-root/
├── metadata.json
├── policies/
│   └── (one policy document per file)
├── schema/             (optional)
│   └── (schema files; format defined by policy_engine)
├── templates/          (optional)
│   └── (one template document per file)
├── entities/           (optional)
│   └── *.json
└── trusted-issuers/    (optional)
    └── *.json
~~~
{: title="Policy Store Directory Layout"}

## Required Files and Directories

`metadata.json`:
: REQUIRED at the policy store root. Contains policy store metadata as defined in Metadata ({{metadata}}).

`policies/`:
: REQUIRED directory. Contains one or more policy files. Each file MUST contain exactly one policy document in a format accepted by the declared policy engine.

## Optional Directories

`schema/`:
: OPTIONAL. When present, contains one or more schema artifacts for the declared policy engine. File names and formats are defined by the policy engine documentation. PDPs that require schema for evaluation MUST reject a policy store that omits `schema/` when schema is required for the policies it contains.

`templates/`:
: OPTIONAL. Contains policy template documents when supported by the policy engine. Each file MUST contain exactly one template document.

`entities/`:
: OPTIONAL. Contains default entity definition files as defined in Default Entities ({{default-entities}}).

`trusted-issuers/`:
: OPTIONAL. Contains trusted issuer configuration files as defined in Trusted Issuers ({{trusted-issuers}}).

# File Naming and Content Requirements

## Policy and Template Files

Files under `policies/` and `templates/` MUST:

* Contain exactly one policy or template document, respectively, in a format valid for the `policy_engine` declared in `metadata.json`.
* Include a stable unique identifier for that policy or template within the policy store, expressed in the manner required by the policy engine (see Policy Identifiers ({{policy-identifiers}})).

Filenames SHOULD use extensions conventional for the declared policy engine. Filenames SHOULD be descriptive but are not required to match policy identifiers.

## Policy Identifiers {#policy-identifiers}

Each policy and template in a policy store MUST be uniquely identifiable within that store. How identifiers are assigned and embedded is **policy engine specific**. For example, Cedar PDPs typically require an `@id()` annotation in each policy file; Cerbos PDPs identify policies by resource kind, name, and version fields within YAML or JSON policy documents.

Tools that are policy engine agnostic MUST preserve policy files without altering engine-specific identifiers.

## Entity Files {#default-entities}

Files under `entities/` MUST:

* Use the `.json` file extension.
* Contain a JSON ({{RFC8259}}) array of entity definitions, or a single entity definition object (which implementations MAY normalize to an array).

Each entity definition MUST include:

`uid`:
: REQUIRED object with `type` and `id` string fields identifying the entity in the policy engine's type system.

`attrs`:
: REQUIRED object containing entity attributes.

`parents`:
: OPTIONAL array of parent entity references for hierarchical relationships. Each reference is an object with `type` and `id` string fields.

`tags`:
: OPTIONAL object of string key-value metadata.

PDPs MAY map this interchange format to engine-native entity representations on load.

## Trusted Issuer Files

Files under `trusted-issuers/` MUST:

* Use the `.json` file extension.
* Contain a single trusted issuer configuration object as defined in Trusted Issuers ({{trusted-issuers}}).

## Schema Files

When the `schema/` directory is present, it MUST contain all schema artifacts required by the declared policy engine for the policies in that store. Layout and file naming within `schema/` are defined by the policy engine. A policy store MAY omit `schema/` entirely; in that case, the PDP MAY obtain schema from another source or operate without packaged schema, according to policy engine capabilities.

# Metadata {#metadata}

The `metadata.json` file provides version and descriptive metadata for the policy store.

## Structure

The top-level JSON object MUST contain the following keys:

`policy_engine`:
: REQUIRED string. Identifies the policy engine (for example, `"cedar"`, `"cerbos"`). Values SHOULD be lowercase alphanumeric strings; hyphen MAY separate words.

`policy_engine_version`:
: REQUIRED string. Version of the policy engine or policy language used by artifacts in this store (for example, `"4.4.0"` for Cedar, or an implementation version for Cerbos).

`policy_store`:
: REQUIRED object containing policy store metadata fields defined below.

### policy_store Object

`id`:
: REQUIRED string. A unique identifier for the policy store, expressed as a hexadecimal string between 15 and 64 characters inclusive.

`name`:
: REQUIRED string. A human-readable name for the policy store.

`description`:
: OPTIONAL string. A human-readable description.

`version`:
: OPTIONAL string. A semantic version of the policy store content (for example, `"1.2.0"`).

`created_date`:
: OPTIONAL string. ISO 8601 date-time when the policy store was created.

`updated_date`:
: OPTIONAL string. ISO 8601 date-time when the policy store was last modified.

Implementations MUST NOT add additional top-level keys to `metadata.json` unless documented by a future revision of this specification. The `policy_store` object MUST NOT contain keys other than those defined here unless documented by a future revision.

### Example (non-normative)

~~~ json
{
  "policy_engine": "cedar",
  "policy_engine_version": "4.4.0",
  "policy_store": {
    "id": "9e96b204911d1c3",
    "name": "Acme Analytics Web Application",
    "description": "Policies for the analytics web application.",
    "version": "1.2.0",
    "created_date": "2025-01-15T10:30:00Z",
    "updated_date": "2025-01-18T14:22:00Z"
  }
}
~~~
{: title="Example metadata.json"}

# Trusted Issuers {#trusted-issuers}

Trusted issuer configuration files describe identity providers whose tokens a PDP MAY accept as evidence during policy evaluation. This enables PDPs to validate JSON Web Tokens ({{RFC7519}}) and map them to principal or entity types in the policy engine's schema.

## Structure

Each trusted issuer file MUST be a JSON object with:

`id`:
: REQUIRED string. Unique identifier for the issuer (hexadecimal, 15–64 characters).

`name`:
: REQUIRED non-empty string. Short human-readable name.

`description`:
: OPTIONAL string.

`configuration_endpoint`:
: REQUIRED string. URI of the issuer configuration document (for example, OpenID Provider Metadata per {{RFC8615}}).

`token_metadata`:
: OPTIONAL object. Maps token type names (such as `access_token`, `id_token`) to per-type configuration objects.

### token_metadata Entry

For each token type key in `token_metadata`, the value object MAY include:

`entity_type_name`:
: REQUIRED when the token type entry is present. Type name in the policy engine's schema used when materializing tokens as principals or entities (for example, `Acme::Access_token` in Cedar, or a Cerbos principal schema reference).

`trusted`:
: OPTIONAL boolean. When `false`, tokens of this type from this issuer MUST be rejected. Default is `true` when omitted.

`required_claims`:
: OPTIONAL array of JWT claim names that MUST be present for the token to be considered valid.

PDP implementations MAY define additional fields within token type entries or at the issuer object level. Such extensions MUST NOT alter the meaning of fields defined in this specification. Interoperable tools SHOULD preserve unknown fields when reading and writing policy stores.

### Example (non-normative)

~~~ json
{
  "id": "3af079fa58a915a4d37a668fb874b7a25b70a37c03cf",
  "name": "Acme Identity Provider",
  "description": "Corporate identity provider",
  "configuration_endpoint": "https://idp.example.com/.well-known/openid-configuration",
  "token_metadata": {
    "access_token": {
      "trusted": true,
      "entity_type_name": "Acme::Access_token",
      "required_claims": ["jti", "iss", "aud", "sub", "exp", "nbf"]
    }
  }
}
~~~
{: title="Example trusted issuer configuration"}

# Archive Format {#archive-format}

The Archive Format packages the Directory Format as a ZIP archive (Constraint JAR, `.cjar`).

## Requirements

* The archive MUST use the ZIP format and `.cjar` file extension.
* Paths inside the archive MUST match the Directory Format layout relative to the policy store root.
* The archive MUST NOT require extraction to a specific absolute path; relative paths MUST be preserved.
* Archive file names SHOULD follow the pattern `{policy-store-name}-{version}.cjar` where `version` matches `policy_store.version` in `metadata.json` when present.

PDPs loading `.cjar` files SHOULD validate structure and required files before evaluation.

# Policy Store Loading

PDPs and tools that load policy stores SHOULD perform the following steps:

1. Detect format (directory or `.cjar` archive) and normalize to a directory view.
2. Verify required files and directories exist.
3. Parse and validate `metadata.json`.
4. Confirm the implementation supports the declared `policy_engine` and `policy_engine_version`, or reject the store.
5. If present, load `schema/`; then load policies and optional templates, entities, and trusted issuers according to policy engine rules.
6. Verify policy engine-specific requirements (such as unique policy identifiers).

Failure at any REQUIRED validation step SHOULD result in rejecting the policy store for evaluation.

# Relationship to AuthZEN

The AuthZEN Authorization API ({{AUTHZEN-API}}) standardizes communication between PEPs and PDPs. This specification does not define API endpoints. It standardizes how policy artifacts are packaged so that:

* PDPs implementing AuthZEN MAY advertise or load policy stores in a portable format regardless of policy engine.
* CI/CD pipelines MAY version, review, and promote policy stores as atomic units.
* Audit systems MAY bind decision logs to a specific `policy_store.id`.

# Security Considerations

## Policy store

Policy stores contain authorization rules and may include sensitive configuration. Implementations MUST protect policy stores at rest and in transit using appropriate access controls for the deployment environment.

Deployments SHOULD use signed releases or secure artifact repositories where integrity and provenance are required.

Trusted issuer configuration determines which token issuers a PDP accepts. Incorrect issuer configuration can allow unauthorized principals. Implementations MUST validate `configuration_endpoint` URIs and token metadata before trusting tokens in production.

Policy stores SHOULD be treated as part of the trusted computing base for authorization decisions. Loading a policy store from an untrusted source without validation is NOT RECOMMENDED.

## Policy store API

PDP should protect this API endpoint by taking appropriate measures to authenticate and authorise the request in accordance with [Authorization API guidelines](https://openid.net/specs/authorization-api-1_0.html#section-11.2)

# IANA Considerations

This document has no IANA actions.

--- back

# JSON Schemas (Informative) {#json-schemas}

The following JSON Schemas illustrate the structure of normative JSON artifacts. They are informative; in case of conflict, the prose requirements in this document take precedence.

## metadata.json Schema

~~~ json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["policy_engine", "policy_engine_version", "policy_store"],
  "properties": {
    "policy_engine": { "type": "string", "minLength": 1 },
    "policy_engine_version": { "type": "string", "minLength": 1 },
    "policy_store": {
      "type": "object",
      "required": ["id", "name"],
      "properties": {
        "id": { "type": "string", "pattern": "^[a-fA-F0-9]{15,64}$" },
        "name": { "type": "string" },
        "description": { "type": "string" },
        "version": { "type": "string" },
        "created_date": { "type": "string", "format": "date-time" },
        "updated_date": { "type": "string", "format": "date-time" }
      },
      "additionalProperties": false
    }
  },
  "additionalProperties": false
}
~~~

## Trusted Issuer Schema

~~~ json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["id", "name", "configuration_endpoint"],
  "properties": {
    "id": { "type": "string", "pattern": "^[a-fA-F0-9]{15,64}$" },
    "name": { "type": "string", "minLength": 1 },
    "description": { "type": "string" },
    "configuration_endpoint": { "type": "string", "format": "uri" },
    "token_metadata": {
      "type": "object",
      "patternProperties": {
        "^[a-zA-Z_][a-zA-Z0-9_]*$": {
          "type": "object",
          "properties": {
            "trusted": { "type": "boolean", "default": true },
            "entity_type_name": { "type": "string", "minLength": 1 },
            "required_claims": {
              "type": "array",
              "items": { "type": "string", "minLength": 1 },
              "uniqueItems": true
            }
          },
          "additionalProperties": true
        }
      },
      "additionalProperties": false
    }
  },
  "additionalProperties": true
}
~~~

## Entity File Schema

~~~ json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "array",
  "items": {
    "type": "object",
    "required": ["uid", "attrs"],
    "properties": {
      "uid": {
        "type": "object",
        "required": ["type", "id"],
        "properties": {
          "type": { "type": "string", "minLength": 1 },
          "id": { "type": "string" }
        },
        "additionalProperties": false
      },
      "attrs": { "type": "object", "additionalProperties": true },
      "parents": {
        "type": "array",
        "items": {
          "type": "object",
          "required": ["type", "id"],
          "properties": {
            "type": { "type": "string", "minLength": 1 },
            "id": { "type": "string" }
          },
          "additionalProperties": false
        }
      },
      "tags": {
        "type": "object",
        "additionalProperties": { "type": "string" }
      }
    },
    "additionalProperties": false
  }
}
~~~

# Policy Engine Examples (Informative) {#examples}

The following examples illustrate how different PDPs MAY populate the same AuthZEN policy store layout. They are not normative.

## Cedar PDP Example

A Cedar-based PDP ({{CEDAR}}) might use `policy_engine` value `"cedar"`, place a Cedar schema file under `schema/`, and use `.cedar` policy files:

~~~ ascii-art
todo-app-policy-store/
├── metadata.json
├── schema/
│   └── app.cedarschema
├── policies/
│   ├── alice-read-access.cedar
│   └── jack-search-access.cedar
├── entities/
│   └── default-roles.json
└── trusted-issuers/
    └── acme-idp.json
~~~

**metadata.json:**

~~~ json
{
  "policy_engine": "cedar",
  "policy_engine_version": "4.4.0",
  "policy_store": {
    "id": "9496b204911615307f6338de8a18c6885f2370793c31",
    "name": "todo_app_policy_store",
    "version": "1.0.0"
  }
}
~~~

**policies/alice-read-access.cedar:**

~~~ cedar
@id("alice-read-policy")
permit(
  principal == App::User::"Alice",
  action == App::Action::"Read",
  resource == App::Application::"todo"
);
~~~

The same store MAY be distributed as `todo-app-policy-store-v1.0.0.cjar`.

## Cerbos PDP Example

A Cerbos PDP ({{CERBOS}}) might use `policy_engine` value `"cerbos"`, store JSON schemas under `schema/`, and use YAML policy files under `policies/`:

~~~ ascii-art
hr-policy-store/
├── metadata.json
├── schema/
│   └── principal.json
├── policies/
│   └── resource_policies/
│       └── leave_request.yaml
└── trusted-issuers/
    └── corp-idp.json
~~~

**metadata.json:**

~~~ json
{
  "policy_engine": "cerbos",
  "policy_engine_version": "0.52.0",
  "policy_store": {
    "id": "a1b2c3d4e5f6789012345678",
    "name": "hr_policy_store",
    "version": "2.0.0"
  }
}
~~~

**policies/resource_policies/leave_request.yaml (excerpt):**

~~~ yaml
apiVersion: api.cerbos.dev/v1
resourcePolicy:
  version: default
  resource: leave_request
  rules:
    - actions: ["view:*"]
      effect: EFFECT_ALLOW
      roles: ["employee"]
~~~

Cerbos deployments that use a native repository layout (for example, a top-level `_schemas` directory) MAY translate to or from this AuthZEN layout when importing or exporting a `.cjar` package.

# Open Issues (Informative) {#open-issues}

The following topics may be addressed in future revisions:

* A registry of recognized `policy_engine` identifier strings.
* Whether policy identifiers MUST be globally unique across policies and templates, and how that interacts with filenames.
* How policy templates are instantiated and linked to policies in multi-file layouts.
* Expression and validation of cross-policy dependencies.
* Subdirectory organization conventions under `policies/` per policy engine.

# Notices

Copyright (c) 2026 The OpenID Foundation.

The OpenID Foundation (OIDF) grants to any Contributor, developer, implementer, or other interested party a non-exclusive, royalty free, worldwide copyright license to reproduce, prepare derivative works from, distribute, perform and display, this draft or final specification solely for the purposes of (i) developing specifications, and (ii) implementing specifications based on such documents, provided that attribution be made to the OIDF as the source of the material, but that such attribution does not indicate an endorsement by the OIDF.

The technology described in this specification was made available from contributions from various sources, including members of the OpenID Foundation and others. Although the OpenID Foundation has taken steps to help ensure that the technology is available for distribution, it takes no position regarding the validity or scope of any intellectual property or other rights that might be claimed to pertain to the implementation or use of the technology described in this specification or the extent to which any license under such rights might or might not be available; neither does it represent that it has made any independent effort to identify any such rights. The OpenID Foundation and the contributors to this specification make no (and hereby expressly disclaim any) warranties (express, implied, or otherwise), including implied warranties of merchantability, non-infringement, fitness for a particular purpose, or title, related to this specification, and the entire risk as to implementing this specification is assumed by the implementer. The OpenID Intellectual Property Rights policy requires contributors to offer a patent promise not to assert certain patent claims against other contributors and against implementers. OpenID invites any interested party to bring to its attention any copyrights, patents, patent applications, or other proprietary rights that may cover technology that may be required to practice this specification.
