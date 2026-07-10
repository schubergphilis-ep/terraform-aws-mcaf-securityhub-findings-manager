# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [7.2.2](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v7.2.1...v7.2.2) (2026-07-10)


### 🐛 Fixes

* improve reliability of the Jira autoclose functionality ([#3](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/issues/3)) ([691be4c](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/691be4c4b7c89f1316d95e6ae4e3b390a215137b))

## [7.2.1](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v7.2.0...v7.2.1) (2026-07-07)


### 🐛 Fixes

* migrate MCAF module sources ([#4](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/issues/4)) ([8e72aaf](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/8e72aafe0ae5bafc703294176ea828abe0e817e8))

## [7.2.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v7.1.0...v7.2.0) (2026-06-25)


### 🚀 Features

* upgrade AWS Lambda Powertools layer from V2 to V3 ([#91](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/91)) ([0f0b701](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/0f0b70145bd07b4fc6c1fd32b66bf7f3a611a477))

### 🐛 Fixes

* bump awsfindingsmanagerlib to 1.5.0 to update dependencies ([#93](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/93)) ([e5f6f26](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/e5f6f26261bd60338db49041659e3805e3d30c04))
* strip bundled lock files from Lambda packages ([#92](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/92)) ([b5ac6be](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/b5ac6be674147c8c8d19a4cbc644510012f7ed66))

## [7.1.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v7.0.0...v7.1.0) (2026-06-05)


### 🚀 Features

* make s3_bucket_name optional by relying on a default bucket prefix ([#90](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/90)) ([b37ba8b](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/b37ba8bf8ea04a9a6e464a7278a84d7a179fb6d7))
* make s3_bucket_name optional by relying on a default bucket prefix ([#90](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/90)) ([b37ba8b](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/b37ba8bf8ea04a9a6e464a7278a84d7a179fb6d7))

## [7.0.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v6.2.0...v7.0.0) (2026-04-01)


### ⚠ BREAKING CHANGES

* Add region support ([#88](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/88))

### 🚀 Features

* Add region support ([#88](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/88)) ([85340f9](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/85340f94ace38a893529be4fad27f439c2d758e7))

## [6.2.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v6.1.0...v6.2.0) (2026-03-10)


### 🚀 Features

* Prevent duplicate jira issue creation ([#86](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/86)) ([67d0448](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/67d0448f29081b6dae64bfae212bda127712aa4c))
* Prevent duplicate jira issue creation ([#86](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/86)) ([67d0448](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/67d0448f29081b6dae64bfae212bda127712aa4c))

## [6.1.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v6.0.0...v6.1.0) (2026-02-23)


### 🚀 Features

* add support for autoclosing Jira tickets for SUPPRESSED findings ([#85](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/85)) ([7fe8cea](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/7fe8cea65beb78aec455c1ae1c30ee1e38e53232))

## [6.0.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v5.4.0...v6.0.0) (2026-02-17)


### ⚠ BREAKING CHANGES

* support for multiple Jira instances to route findings to different Jira projects based on AWS account IDs ([#81](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/81))

### 🚀 Features

* support for multiple Jira instances to route findings to different Jira projects based on AWS account IDs ([#81](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/81)) ([c79be47](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/c79be4792522c603b8ac18ffdbeb8109766c75b1))

## [5.4.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v5.3.0...v5.4.0) (2025-12-30)


### 🚀 Features

* prevent informational checks sent to findings manager ([#80](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/80)) ([475227f](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/475227f2a4c1149b3dbe4f55087a2a68ac57b2c4))
* prevent informational checks sent to findings manager ([#80](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/80)) ([475227f](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/475227f2a4c1149b3dbe4f55087a2a68ac57b2c4))

## [5.3.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v5.2.0...v5.3.0) (2025-11-04)


### 🚀 Features

* Adding support to pass optional Jira intermediate transition before closing the finding ([#79](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/79)) ([f8e4b94](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/f8e4b9486a10e4c3cc0a092a89d676ae5e9c8a14))

## [5.2.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v5.1.1...v5.2.0) (2025-10-13)


### 🚀 Features

* Adding ProductName filtering feature ([#78](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/78)) ([01e812d](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/01e812d3d306562f488a02f0e5acd3229d32c511))

## [5.1.1](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v5.1.0...v5.1.1) (2025-10-09)


### 🐛 Fixes

* Jira close ticket step function definition update ([#77](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/77)) ([ed4b39e](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/ed4b39e87a216fb3643a7dd55373d3fb42a91443))

## [5.1.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v5.0.5...v5.1.0) (2025-10-06)


### 🚀 Features

* Adding include_account_filter to support inclusion case for Jira integration ([#75](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/75)) ([109e6fd](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/109e6fdef9e146c50cbc33c22e083f1b51646a5e))

## [5.0.5](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v5.0.4...v5.0.5) (2025-09-25)


### 🐛 Fixes

* security: Removing version pin due to vulnerability in v1.26.19 ([#74](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/74)) ([e2cd629](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/e2cd629574c24bb2c8e049a1484c9972677d3820))

## [5.0.4](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v5.0.3...v5.0.4) (2025-09-16)

## [5.0.3](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v5.0.2...v5.0.3) (2025-08-08)


### 🐛 Fixes

* remove old dependencies in lambda packages ([#70](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/70)) ([34fad2c](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/34fad2cb1eafbd373222cb498ea8abcc34a3886e))

## [5.0.2](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v5.0.1...v5.0.2) (2025-08-07)


### 🐛 Fixes

* bump Jira dependency with security issue ([#69](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/69)) ([6353dd7](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/6353dd766719cc7309eb7665cf1c96c7f1dc96ec))

## [5.0.1](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v5.0.0...v5.0.1) (2025-06-17)


### 🐛 Fixes

* fix the logic to retrieve jira client ([#68](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/68)) ([bb75191](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/bb75191ccd5677c67d9616042bb20a5f9ad50e7f))

## [5.0.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v4.1.1...v5.0.0) (2025-06-05)


### 🚀 Features

* to store jira credentials support both secretsmanager and ssm parameters instead of only secretsmanager ([#67](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/67)) ([095c7f7](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/095c7f73b31d20f0f6592e845db285337c9fa680))

## [4.1.1](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v4.1.0...v4.1.1) (2025-04-16)


### 🐛 Fixes

* ensuring the Lambda `findings-manager-jira` exits ungracefully when there is an error + text updates. ([#66](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/66)) ([0416828](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/041682809522c4e6dcd48d9e459cabc000910b82))

## [4.1.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v4.0.1...v4.1.0) (2025-04-07)


### 🚀 Features

* allow filtering SecurityHub findings by regions ([#65](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/65)) ([813e92d](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/813e92de31c9af18a34ba82b694de0904697fe2f))

## [4.0.1](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v4.0.0...v4.0.1) (2025-03-17)


### 🐛 Fixes

* Adds ListBucket permission for lambda ([#64](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/64)) ([a1904d5](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/a1904d5071f2608fff13b259599deec5734618e8))
* jira integration errors for inspector findings ([#63](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/63)) ([53e8140](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/53e8140b9ce203fd4de3faea55a95d7ebb24fe03))

## [4.0.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v3.5.1...v4.0.0) (2025-02-06)


### 🚀 Features

* breaking: lambda timeout suppression processing ([#61](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/61)) ([46e10b0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/46e10b0bed3620e337dc8ad9f01d62001fc480ca))

### 🐛 Fixes

* breaking: lambda timeout suppression processing ([#61](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/61)) ([46e10b0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/46e10b0bed3620e337dc8ad9f01d62001fc480ca))

## [3.5.1](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v3.5.0...v3.5.1) (2025-01-07)


### 🐛 Fixes

* improved logging for suppressor ([#60](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/60)) ([95cbdf3](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/95cbdf389238c7994497f57157b2d10b3e78a57c))

## [3.5.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v3.4.0...v3.5.0) (2024-12-24)


### 🐛 Fixes

* solve various issues ([#58](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/58)) ([e1d1964](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/e1d1964e1481b911aa30e7cb4c8edf907beb5c39))
* solve various issues ([#58](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/58)) ([e1d1964](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/e1d1964e1481b911aa30e7cb4c8edf907beb5c39))
* increasing timeouts and memory usage on lambdas to prevent lambda timeouts ([#57](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/57)) ([57fa615](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/57fa615425c01e41d053643ee8d0a7d180a5d063))

## [3.4.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v3.3.2...v3.4.0) (2024-11-21)


### 🚀 Features

* adds support for Security Hub Integration findings ([#55](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/55)) ([d0efb61](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/d0efb61a44a4143b27e2cb9963f91805360d167c))

## [3.3.2](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v3.3.1...v3.3.2) (2024-11-14)


### 🐛 Fixes

* reduce jira lambda executions when autoclose is enabled ([#54](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/54)) ([7a892ec](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/7a892ec8739302a50270381b70565b7587d6da8f))

## [3.3.1](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v3.3.0...v3.3.1) (2024-11-11)


### 🐛 Fixes

* bug: fix issues with known after apply issues for s3 and lambda roles ([#53](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/53)) ([cfc69dd](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/cfc69dd982b04396c484d4006e6f2ae7659d1ed5))

## [3.3.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v3.2.2...v3.3.0) (2024-11-04)


### 🚀 Features

* Jira integration - option to add custom fields to created issues ([#50](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/50)) ([d3f42f8](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/d3f42f8d970370e0a5d74e5dcc02a8e7466a72cf))
* Jira autoclose improvements ([#52](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/52)) ([da5ebc1](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/da5ebc1eb723a70d7830b057154162efab8e4c12))

### 🐛 Fixes

* updated lambda packages are not uploaded to S3 ([#51](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/51)) ([f751ef1](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/f751ef1ec569b935d9728597c7e0d91eb834e1c6))

## [3.2.2](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v3.2.1...v3.2.2) (2024-10-14)


### 🐛 Fixes

* missing CloudWatch permissions for step function logging ([#49](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/49)) ([80a3d65](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/80a3d65f86bbbbddd5f471ebb51c43ed216875d1))

## [3.2.1](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v3.2.0...v3.2.1) (2024-10-14)


### 🐛 Fixes

* missing variable defaults for step_function_settings ([#48](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/48)) ([0d775f3](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/0d775f3e79686d2b11dd2291b79d5b1dd38963df))

## [3.2.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v3.1.2...v3.2.0) (2024-10-14)


### 🚀 Features

* findings-manager-jira refactoring and ticket autoclose support ([#46](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/46)) ([f6473bb](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/f6473bbc92e371fc0d62c42edf1835bfb82aed21))
* Adds logging to the step function ([#47](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/47)) ([129fe66](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/129fe6656cf55afb13db0ad25a360b79bb51994a))

## [3.1.2](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v3.1.1...v3.1.2) (2024-09-12)


### 🐛 Fixes

* solve deprecation warning use data resource of archive file ([#44](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/44)) ([67d99c5](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/67d99c5917ac3a0c53828a1b1d4bd91fb0b90c69))

## [3.1.1](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v3.1.0...v3.1.1) (2024-09-12)


### 🐛 Fixes

* solve deprecation warning use data resource of archive file ([#43](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/43)) ([43af497](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/43af497aa606824ce549432fa209af5430a56762))

## [3.1.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v3.0.0...v3.1.0) (2024-09-12)


### 🚀 Features

* upgrade python version from 3.8 to 3.12 & package lambda code using github action ([#42](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/42)) ([459ae48](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/459ae48b35f0d6049762a61dc314975e014f27b8))

## [3.0.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v2.2.0...v3.0.0) (2024-08-02)


### 🚀 Features

* breaking(gsn-11066): apply naming convention ([#38](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/38)) ([d983ccc](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/d983ccc94e07d4e12b07608abeb1612a07538af6))
* breaking(gsn-10597): use awsfindingsmanagerlib python library ([#33](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/33)) ([a5cce2a](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/a5cce2a00326a4c7f108b45330428686539a7386))

### 🐛 Fixes

* fix deployment issues ([#39](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/39)) ([6d88c21](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/6d88c217ce2975924bfdb528deef0f7396aa10e8))

## [2.2.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v2.1.0...v2.2.0) (2024-06-26)


### 🚀 Features

* add variable to filter findings forwarded to SNOW based on severity label ([#35](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/35)) ([084fb1b](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/084fb1bc4d6921987e20e95ee9cf64f2d05c873f))

## [2.1.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v2.0.1...v2.1.0) (2024-01-23)


### 🚀 Features

* enhancement: Set dynamoDB deletion protection to true to solve security hub finding ([#30](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/30)) ([3130d5c](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/3130d5c97f22b5d6e219813a7087cc1b97a338a7))

## [2.0.1](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v2.0.0...v2.0.1) (2023-11-21)


### 🐛 Fixes

* Ensure ServiceNow Sync User can update Security Hub findings ([#24](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/24)) ([dc46fc9](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/dc46fc9439c7aeb3e7c385986c5e53d6e4c2bf35))

## [2.0.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v1.0.0...v2.0.0) (2023-10-05)


### 🚀 Features

* breaking: update mcaf-lambda to latest version, allow configuration of runtime, allow configuration of Jira lambda egress ([#22](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/22)) ([4c1051a](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/4c1051a8a36e5f60abb71c0b631581a2e471735e))

### 🐛 Fixes

* bump s3 module ([#19](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/19)) ([518d272](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/518d27258c1cdd23359165b33001b0a84810f508))

## [1.0.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v0.3.0...v1.0.0) (2023-08-14)


### 🚀 Features

* breaking: move variables to objects and improve settings ([#13](https://github.com/schubergphilis/terraform-aws-mcaf-securityhub-findings-manager/pull/13)) ([8cd8cf6](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/commit/8cd8cf65690a3e0539cb181bde581f6e1ca8349e))

## [0.3.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v0.2.0...v0.3.0) (2023-04-03)

## [0.2.0](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v0.1.1...v0.2.0) (2023-01-24)

## [0.1.1](https://github.com/schubergphilis-ep/terraform-aws-mcaf-securityhub-findings-manager/compare/v0.1.0...v0.1.1) (2022-11-15)

## 0.1.0 (2022-09-28)
