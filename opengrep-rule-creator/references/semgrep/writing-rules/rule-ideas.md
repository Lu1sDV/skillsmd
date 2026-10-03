> **Upstream Semgrep documentation snapshot — NOT an OpenGrep compatibility promise.** Retrieved and locally modified 2026-10-03 (offline links, presentation wrappers, resolved playground examples). Semgrep and upstream contributors; LGPL-2.1, provided without warranty. [License](../LICENSE); [offline index](../INDEX.md). Source: https://docs.semgrep.dev/writing-rules/rule-ideas.md

> ## Documentation Index
> Local adaptation: read the [downloaded documentation index](../discovery/llms.txt) rather than fetching https://docs.semgrep.dev/llms.txt.
> Use this file to discover all available pages before exploring further.

# Rule structure syntax examples

> Not sure what to write a rule for? Below are some common questions, ideas, and topics to spur your imagination. Happy hacking! 💡

## Automate code review comments

*Time to write this rule: **5 minutes***

You can use Semgrep and its GitHub integration to [automate PR comments](https://docs.semgrep.dev/semgrep-appsec-platform/notifications) that you frequently make in code reviews. Writing a custom rule for the code pattern you want to target is usually straightforward. If you want to understand the Semgrep syntax, see the [documentation](pattern-syntax.md) or try the [tutorial](https://semgrep.dev/learn).



  <img src="../assets/semgrep-ci-4c94be66f30fef156679254592d3e2b1.gif" alt="A reviewer writes a Semgrep rule and adds it to an organization-wide policy" width="638" height="356" data-path="images/semgrep-ci-4c94be66f30fef156679254592d3e2b1.gif" />



A reviewer writes a Semgrep rule and adds it to an organization-wide policy.

## Ban dangerous APIs

*Time to write this rule: **5 minutes***

Semgrep can detect dangerous APIs in code. If integrated into CI/CD pipelines, you can use Semgrep to block merges or flag for review when someone adds such dangerous APIs to the code. For example, a rule that detects React's `dangerouslySetInnerHTML` looks like this.



  
[Offline playground rule and complete test cases](../playground/zEXn.md). Original interactive execution: [https://semgrep.dev/embed/editor?snippet=zEXn](https://semgrep.dev/embed/editor?snippet=zEXn) (external).




## Exempt special cases of dangerous APIs

*Time to write this rule: **5 minutes***

If you have a legitimate use case for a dangerous API, you can exempt a specific use of the API using a `nosemgrep` comment. The rule below checks for React's `dangerouslySetInnerHTML`, but the code is annotated with a `nosemgrep` comment. Semgrep will not detect this line. This allows Semgrep to continuously check for future uses of `dangerouslySetInnerHTML` while allowing for this specific use.



  
[Offline playground rule and complete test cases](../playground/2B3r.md). Original interactive execution: [https://semgrep.dev/embed/editor?snippet=2B3r](https://semgrep.dev/embed/editor?snippet=2B3r) (external).




## Detect tainted data flowing into a dangerous sink

*Time to write this rule: **5 minutes***

Semgrep's [dataflow engine with support for taint tracking](data-flow/data-flow-overview.md) can be used to detect when data flows from a user-provided value into a security-sensitive function.

This rule detects when a user of the ExpressJS framework passes user data into the `run()` method of a sandbox.



  
[Offline playground rule and complete test cases](../playground/jEGP.md). Original interactive execution: [https://semgrep.dev/embed/editor?snippet=jEGP](https://semgrep.dev/embed/editor?snippet=jEGP) (external).




## Detect security violations

*Time to write this rule: **5 minutes***

Use Semgrep to flag specific uses of APIs too, not just their presence in code. We jokingly call these the "security off" buttons and make extensive use of Semgrep to detect them.

This rule detects when HTML auto-escaping is explicitly disabled for a Django template.



  
[Offline playground rule and complete test cases](../playground/9Yjy.md). Original interactive execution: [https://semgrep.dev/embed/editor?snippet=9Yjy](https://semgrep.dev/embed/editor?snippet=9Yjy) (external).




## Scan configuration files using JSON, YAML, or generic pattern matching

*Time to write this rule: **10 minutes***

Semgrep [natively supports JSON and YAML](https://docs.semgrep.dev/supported-languages) and can be used to write rules for configuration files. This rule checks for skipped TLS verification in Kubernetes clusters.



  
[Offline playground rule and complete test cases](../playground/rEqJ.md). Original interactive execution: [https://semgrep.dev/embed/editor?snippet=rEqJ](https://semgrep.dev/embed/editor?snippet=rEqJ) (external).




The [Generic pattern matching](generic-pattern-matching.md) mode is for languages and file formats that Semgrep does not natively support. For example, you can write rules for Dockerfiles using the generic mode. The Dockerfile rule below checks for invalid port numbers.



  
[Offline playground rule and complete test cases](../playground/NGXN.md). Original interactive execution: [https://semgrep.dev/embed/editor?snippet=NGXN](https://semgrep.dev/embed/editor?snippet=NGXN) (external).




## Enforce authentication patterns

*Time to write this rule: **15 minutes***

If a project has a "correct" way of doing authentication, Semgrep can be used to enforce this so that authentication mishaps do not happen. In the example below, this Flask app requires an authentication decorator on all routes. The rule detects routes that are missing authentication decorators. If deployed in CI/CD pipelines, Semgrep can block undecorated routes or flag a security member for further investigation.



  
[Offline playground rule and complete test cases](../playground/wEQd.md). Original interactive execution: [https://semgrep.dev/embed/editor?snippet=wEQd](https://semgrep.dev/embed/editor?snippet=wEQd) (external).




## Systematize project-specific coding patterns

*Time to write this rule: **10 minutes***

Automate institutional knowledge using Semgrep. This has several benefits, including teaching new members about coding patterns in an automatic way and keeping a project up-to-date with coding patterns. If you keep coding guidelines in a document, converting these into Semgrep rules is a great way to free developers from having to remember all the guidelines.

In this example, a legacy API requires calling `verify_transaction(t)` before calling `make_transaction(t)`. The Semgrep rule below detects when these methods are not called correctly.



  
[Offline playground rule and complete test cases](../playground/Nr3z.md). Original interactive execution: [https://semgrep.dev/embed/editor?snippet=Nr3z](https://semgrep.dev/embed/editor?snippet=Nr3z) (external).




## Extract information with metavariables

*Time to write this rule: **15 minutes***

Semgrep metavariables can be used as output in the `message` key. This can be used to extract and collate information about a codebase. Click through to [this example](https://semgrep.dev/s/ORpk), which extracts Java Spring routes. This can be used to quickly see all the exposed routes of an application.

## Detect deprecated APIs

*Time to write this rule: **5 minutes***

Semgrep can detect deprecated APIs just as easily as dangerous APIs. Identifying deprecated API calls can help an application migrate to current or future versions.

This rule example detects a function that is deprecated as of Django 4.0.



  
[Offline playground rule and complete test cases](../playground/vEQ0.md). Original interactive execution: [https://semgrep.dev/embed/editor?snippet=vEQ0](https://semgrep.dev/embed/editor?snippet=vEQ0) (external).




## Promote secure alternatives

*Time to write this rule: **5 minutes***

Some libraries or APIs have safe alternatives, such as [Google's `re2`](https://github.com/google/re2), an implementation of the standard `re` interface that ships with Python that is resistant to regular expression denial-of-service. This rule detects the use of `re` and recommends `re2` as a safe alternative with the same interface.



  
[Offline playground rule and complete test cases](../playground/ZoA4.md). Original interactive execution: [https://semgrep.dev/embed/editor?snippet=ZoA4](https://semgrep.dev/embed/editor?snippet=ZoA4) (external).




## Prompts for writing custom rules

Try answering these questions to uncover important rules for your project.

1. From recent post-mortems: what code issues contributed to it?
2. \[XYZ] is a (security, performance, other) library that everyone should use, but they don’t consistently.
3. When you review code, what changes do you frequently ask for?
4. What vulnerability classes from bug bounty submissions recur (or appear in different places of the codebase)?
5. Are there engineering or performance patterns? Consistent exception handlers?
6. What issues were caused by misconfigurations in Infrastructure-as-Code files (JSON)?
7. What are some “invariants” that should hold about your code - things that should always or never be true (for example, every admin route checks if the user is an admin)?
8. What methods/APIs are deprecated and you’re trying to move away from?
