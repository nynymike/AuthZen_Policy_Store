---
stand_alone: true
ipr: none
cat: std
submissiontype: IETF
wg: OpenID AuthZEN

docname: draft-schwartz-authzen-policy-store

title: Cedar Policy Store Format
abbrev: policy-store
lang: en
kw:
 - Authorization
 - Cedar
 - Policy Store
 - PDP
 - AuthZEN

author:
- role: editor
  ins: M. Schwartz
  name: Michael Schwartz
  org: Independent Contributor
  email: mike@gluu.org
- role: editor
  ins: D. Desai
  name: Dhaval Desai
  org: Independent Contributor
  email: dhaval.desai@gmail.com

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
 CEDAR-JSON:
   title: Cedar JSON Entity Format
   target: https://docs.cedarpolicy.com/schema/json-schema.html
   author:
   - name: Cedar Team
     org: Amazon Web Services
 AUTHZEN-API:
   title: Authorization API 1.0
   target: https://openid.net/specs/authorization-api-1_0.html
   author:
   - name: OpenID AuthZEN Working Group
     org: OpenID Foundation

--- abstract

This document defines the Cedar Policy Store Format, a structured packaging format for co-locating Cedar policies, schema, default entities, trusted token issuers, and related metadata required for authorization evaluation. The format supports a directory structure for development and version control, and a compressed archive format (`.cjar`) for distribution and deployment. Policy stores packaged in this format improve interoperability among Policy Decision Points (PDPs), tooling, and the OpenID AuthZEN ecosystem.

--- middle

# Introduction

Cedar is a policy language for fine-grained authorization. Cedar does not prescribe how policies, schema, and supporting configuration are stored or versioned together. In practice, policies are written against a specific schema and evaluated with a consistent set of default entities and trusted token issuers. Without a standard packaging format, organizations adopt ad hoc conventions, which impedes portability, auditability, and interoperability among PDPs and third-party tools.

The OpenID AuthZEN Working Group defines protocols and patterns for authorization interoperability, including the Authorization API ({{AUTHZEN-API}}). This specification complements AuthZEN by defining a portable, self-contained **policy store** format that PDPs and tooling can load, validate, and exchange without proprietary layout conventions.

This document defines version 1.0 of the Cedar Policy Store Format.

# Conventions and Definitions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in BCP 14 ({{RFC2119}}) when, and only when, they appear in all capitals, as shown here.

## Terminology

Policy Store:
: A structured collection of Cedar policies, schema, and related artifacts bound together for evaluation, as defined in this document.

Directory Format:
: A policy store represented as a folder hierarchy on a filesystem.

Archive Format:
: A policy store packaged as a ZIP archive with the `.cjar` file extension.

Policy Decision Point (PDP):
: A component that evaluates authorization requests against policies. See {{AUTHZEN-API}}.

Manifest:
: The `manifest.json` file that inventories policy store files and optional integrity metadata.

# Overview

A policy store bundles the artifacts required to evaluate Cedar authorization requests against a known schema and configuration baseline:

* Cedar schema (`schema.cedarschema`)
* Cedar policies (one policy per file under `policies/`)
* Optional Cedar policy templates (`templates/`)
* Optional default entities (`entities/`)
* Optional trusted issuer configuration (`trusted-issuers/`)
* Required metadata (`metadata.json`)
* Required manifest (`manifest.json`)

Implementations MAY support either the Directory Format or the Archive Format, or both. Tools that produce or consume policy stores SHOULD support conversion between formats without loss of content.

The Archive Format is a ZIP archive containing the same relative paths as the Directory Format. Archive files MUST use the `.cjar` extension.

# Directory Structure

The root of a policy store (directory or archive) is referred to as the **policy store root**. The following layout is REQUIRED for conformant policy stores:

~~~ ascii-art
policy-store-root/
├── metadata.json
├── manifest.json
├── schema.cedarschema
├── policies/
│   └── *.cedar
├── templates/          (optional)
│   └── *.cedar
├── entities/           (optional)
│   └── *.json
└── trusted-issuers/    (optional)
~~~
{: title="Policy Store Directory Layout"}

## Required Files and Directories

`metadata.json`:
: REQUIRED at the policy store root. Contains policy store metadata as defined in Metadata ({{metadata}}).

`manifest.json`:
: REQUIRED at the policy store root. Contains the file inventory as defined in Manifest ({{manifest}}).

`schema.cedarschema`:
: REQUIRED at the policy store root. Contains the Cedar schema in Cedar schema syntax ({{CEDAR}}).

`policies/`:
: REQUIRED directory. Contains one or more `.cedar` policy files.

## Optional Directories

`templates/`:
: OPTIONAL. Contains Cedar policy template files.

`entities/`:
: OPTIONAL. Contains default entity definition files in Cedar JSON entity format ({{CEDAR-JSON}}).

`trusted-issuers/`:
: OPTIONAL. Contains trusted issuer configuration files used by PDPs to validate and map tokens to Cedar entities.

# File Naming and Content Requirements

## Policy and Template Files

Files under `policies/` and `templates/` MUST:

* Use the `.cedar` file extension.
* Contain exactly one Cedar policy or template, respectively.
* Include a Cedar `@id()` annotation that uniquely identifies the policy or template within the policy store.

Policy and template identifiers MUST be stable across versions of a policy store when the policy or template semantics are unchanged. Filenames SHOULD be descriptive but are not required to match `@id()` values.

## Entity Files

Files under `entities/` MUST:

* Use the `.json` file extension.
* Contain a JSON ({{RFC8259}}) array of entity definitions, or a single entity definition object (which implementations MAY normalize to an array).

Each entity definition MUST conform to the Cedar JSON entity format ({{CEDAR-JSON}}) and include:

`uid`:
: REQUIRED object with `type` and `id` string fields identifying the entity.

`attrs`:
: REQUIRED object containing entity attributes.

`parents`:
: OPTIONAL array of parent entity references for hierarchical relationships.

`tags`:
: OPTIONAL object of string key-value metadata.

## Trusted Issuer Files

Files under `trusted-issuers/` MUST:

* Use the `.json` file extension.
* Contain a single trusted issuer configuration object as defined in Trusted Issuers ({{trusted-issuers}}).

## Schema File

The schema file MUST be named `schema.cedarschema` and MUST contain a valid Cedar schema ({{CEDAR}}) for the policies in the policy store.

# Metadata {#metadata}

The `metadata.json` file provides version and descriptive metadata for the policy store.

## Structure

The top-level JSON object MUST contain the following keys:

`cedar_version`:
: REQUIRED string. The version of the Cedar policy language used by policies in this policy store (for example, `"4.4.0"`).

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
  "cedar_version": "4.4.0",
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

# Manifest {#manifest}

The `manifest.json` file provides an inventory of files in the policy store for validation and integrity checking.

## Structure

`policy_store_id`:
: REQUIRED string. MUST match `policy_store.id` from `metadata.json`.

`generated_date`:
: OPTIONAL string. ISO 8601 date-time when the manifest was generated.

`files`:
: REQUIRED object. Keys are relative paths from the policy store root (using forward slashes). Values are objects with:

`size`:
: OPTIONAL number. Size of the file in bytes.

`checksum`:
: OPTIONAL string. Integrity checksum in the form `sha256:` followed by a lowercase hexadecimal SHA-256 digest.

Implementations SHOULD verify that every file listed in `files` exists in the policy store and that optional checksums match. Implementations MAY reject policy stores where `policy_store_id` does not match `metadata.json`.

### Example (non-normative)

~~~ json
{
  "policy_store_id": "9496b204911615307f6338de8a18c6885f2370793c31",
  "generated_date": "2025-01-18T14:22:00Z",
  "files": {
    "metadata.json": {
      "size": 245,
      "checksum": "sha256:a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3"
    },
    "schema.cedarschema": {
      "size": 1024,
      "checksum": "sha256:b3a8e0e1f9ab1bfe3a36f231f676f78bb30a519d2b21e6c530c0b86a4c4700e2"
    },
    "policies/alice-read-access.cedar": {
      "size": 156,
      "checksum": "sha256:c2d4e6f2a1b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9"
    }
  }
}
~~~
{: title="Example manifest.json"}

# Trusted Issuers {#trusted-issuers}

Trusted issuer configuration files describe identity providers whose tokens a PDP MAY accept as evidence during policy evaluation. This enables PDPs to validate JSON Web Tokens ({{RFC7519}}) and map them to Cedar entity types declared in the schema.

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
: REQUIRED when the token type entry is present. Cedar entity type name (for example, `Jans::Access_token`) used when materializing tokens as entities.

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

The Archive Format packages the Directory Format as a ZIP archive.

## Requirements

* The archive MUST use the ZIP format and `.cjar` file extension.
* Paths inside the archive MUST match the Directory Format layout relative to the policy store root.
* The archive MUST NOT require extraction to a specific absolute path; relative paths MUST be preserved.
* Archive file names SHOULD follow the pattern `{policy-store-name}-{version}.cjar` where `version` matches `policy_store.version` in `metadata.json` when present.

Tools MAY generate manifests over archive contents before distribution. PDPs loading `.cjar` files SHOULD validate structure, required files, manifest consistency, and optional checksums before evaluation.

# Policy Store Loading

PDPs and tools that load policy stores SHOULD perform the following steps:

1. Detect format (directory or `.cjar` archive) and normalize to a directory view.
2. Verify required files and directories exist.
3. Parse and validate `metadata.json` and `manifest.json`.
4. If checksums are present, verify file integrity.
5. Load `schema.cedarschema`, then policies and optional templates, entities, and trusted issuers.
6. Verify each policy and template has an `@id()` annotation and that policy language version is compatible with `cedar_version`.

Failure at any REQUIRED validation step SHOULD result in rejecting the policy store for evaluation.

# Relationship to AuthZEN

The AuthZEN Authorization API ({{AUTHZEN-API}}) standardizes communication between PEPs and PDPs. This specification does not define API endpoints. It standardizes how Cedar policy artifacts are packaged so that:

* PDPs implementing AuthZEN MAY advertise or load policy stores in a portable format.
* CI/CD pipelines MAY version, review, and promote policy stores as atomic units.
* Audit systems MAY bind decision logs to a specific `policy_store.id` and manifest checksums.

# Security Considerations

Policy stores contain authorization rules and may include sensitive configuration. Implementations MUST protect policy stores at rest and in transit using appropriate access controls for the deployment environment.

Checksums in `manifest.json` are RECOMMENDED to detect tampering. Checksums alone do not provide authenticity; deployments SHOULD combine manifests with signed releases or secure artifact repositories where integrity and provenance are required.

Trusted issuer configuration determines which token issuers a PDP accepts. Incorrect issuer configuration can allow unauthorized principals. Implementations MUST validate `configuration_endpoint` URIs and token metadata before trusting tokens in production.

Policy stores SHOULD be treated as part of the trusted computing base for authorization decisions. Loading a policy store from an untrusted source without validation is NOT RECOMMENDED.

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
  "required": ["cedar_version", "policy_store"],
  "properties": {
    "cedar_version": { "type": "string" },
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
            "entity_type_name": {
              "type": "string",
              "pattern": "^[a-zA-Z_][a-zA-Z0-9_]*::[a-zA-Z_][a-zA-Z0-9_]*$"
            },
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

# Examples (Informative) {#examples}

## Todo Application Policy Store

~~~ ascii-art
todo-app-policy-store/
├── metadata.json
├── manifest.json
├── schema.cedarschema
├── policies/
│   ├── alice-read-access.cedar
│   └── jack-search-access.cedar
├── entities/
│   └── default-roles.json
└── trusted-issuers/
    └── jans-idp.json
~~~

**policies/alice-read-access.cedar:**

~~~ cedar
@id("alice-read-policy")
permit(
  principal == Jans::User::"Alice",
  action == Jans::Action::"Read",
  resource == Jans::Application::"todo"
);
~~~

**entities/default-roles.json:**

~~~ json
[
  {
    "uid": { "type": "Jans::Role", "id": "Searchable" },
    "attrs": {
      "name": "Searchable",
      "permissions": ["search", "read"]
    }
  }
]
~~~

The same content MAY be distributed as `todo-app-policy-store-v1.0.0.cjar`.

# Open Issues (Informative) {#open-issues}

The following topics may be addressed in future revisions:

* Whether policy `@id()` values MUST be unique across policies and templates, and relationship to filenames.
* How policy templates are instantiated and linked to policies in multi-file layouts.
* Expression and validation of cross-policy dependencies.
* Namespace-based subdirectory organization under `policies/`.

# Notices

Copyright (c) 2026 The OpenID Foundation.

The OpenID Foundation (OIDF) grants to any Contributor, developer, implementer, or other interested party a non-exclusive, royalty free, worldwide copyright license to reproduce, prepare derivative works from, distribute, perform and display, this draft or final specification solely for the purposes of (i) developing specifications, and (ii) implementing specifications based on such documents, provided that attribution be made to the OIDF as the source of the material, but that such attribution does not indicate an endorsement by the OIDF.

The technology described in this specification was made available from contributions from various sources, including members of the OpenID Foundation and others. Although the OpenID Foundation has taken steps to help ensure that the technology is available for distribution, it takes no position regarding the validity or scope of any intellectual property or other rights that might be claimed to pertain to the implementation or use of the technology described in this specification or the extent to which any license under such rights might or might not be available; neither does it represent that it has made any independent effort to identify any such rights. The OpenID Foundation and the contributors to this specification make no (and hereby expressly disclaim any) warranties (express, implied, or otherwise), including implied warranties of merchantability, non-infringement, fitness for a particular purpose, or title, related to this specification, and the entire risk as to implementing this specification is assumed by the implementer. The OpenID Intellectual Property Rights policy requires contributors to offer a patent promise not to assert certain patent claims against other contributors and against implementers. OpenID invites any interested party to bring to its attention any copyrights, patents, patent applications, or other proprietary rights that may cover technology that may be required to practice this specification.
