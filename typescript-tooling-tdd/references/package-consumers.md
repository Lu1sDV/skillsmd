# Package Consumer Checks

Use this procedure when changing published entry points, declarations, module output, packaging, or supported consumers. Validate the artifact that consumers receive with the repository's existing build tools.

## Define the supported surface

Read `package.json`, export conditions/subpaths, included files, declaration settings, runtime requirements, peer dependencies, and release CI. Identify the consumers the package actually promises; an ESM-only package does not need a CJS build merely to complete this check.

| Contract | Evidence to collect |
| --- | --- |
| Public entry points | Root and promised subpath imports resolve from the installed package |
| Runtime/module support | Built code loads and representative behavior works in promised environments |
| Type support | Consumer compilation resolves declarations under supported compiler/resolution settings |
| Published contents | Export targets, declarations, and required runtime assets exist in the archive |
| Dependencies | Consumer setup supplies declared runtime/peer dependencies without producer-only tooling |

Keep the runtime needed to build the package separate from the runtimes it supports after installation.

## Build and pack the real artifact

1. Inspect build/pack scripts and lifecycle hooks before executing them. Use the existing package manager and release preparation steps; distinguish these from publication or deployment.
2. Build the affected package, then create its archive with the repository's pack command (`npm pack` for an npm-managed package). A dry-run inventory helps inspect contents but is not the installable artifact.
3. Inspect the archive's manifest and file list. Confirm every promised export condition points to shipped output and that declaration imports resolve to shipped files or declared dependencies.
4. Check that the artifact reflects this build rather than stale output. Do not assume workspace source tests establish what a clean consumer will install.

## Exercise an isolated consumer

1. Install the archive into a temporary consumer outside the producer workspace, using existing fixture/toolchain conventions. Avoid source symlinks, workspace aliases, and producer-only resolution paths.
2. Import the package by its published name and exercise each promised entry point. Check the resolved locations when there is any doubt that the installed artifact is being used.
3. Run a focused runtime smoke test for meaningful exports and required assets. Test `import` and `require` only where those forms are supported; preserve the consumer's real module semantics.
4. Compile representative consumer calls against the installed declarations using the supported TypeScript/resolution combinations. Include a rejected call when it protects a changed public type contract.
5. For dual output, exercise both formats and their matching declarations. One source type check does not prove both outputs; declaration interpretation must agree with the corresponding JavaScript module kind.
6. Repeat for materially different promised runtimes or consumers, using existing CI fixtures where possible. A fixture importing `src/` or relying on a monorepo alias does not count as package evidence.

Limit the matrix to the compatibility contract and the changed risk. Retain a failing consumer fixture when it provides a useful packaging regression test.

## Optional package analyzers

Use an existing `publint` setup for package metadata/output compatibility and Are the Types Wrong? (`attw`) for declaration/module-resolution mismatches. Follow the installed version's CLI and select a profile matching promised consumers; do not silence relevant failures to obtain a pass.

Prefer repository scripts or installed binaries. If analyzers are absent, record the manual checks performed and propose their addition only when justified. Static package analysis complements the isolated runtime/type checks; it does not establish application behavior.

## Completion evidence

Report the archive tested, entry points, consumer runtime/compiler settings, exact check outcomes, and any untested promised environment. Packing and consumer validation do not require publishing a package.

## Primary references

- [npm pack and archive behavior](https://docs.npmjs.com/cli/v11/commands/npm-pack/)
- [TypeScript library and dual-output constraints](https://www.typescriptlang.org/docs/handbook/modules/guides/choosing-compiler-options.html)
- [Node package entry points and conditional exports](https://nodejs.org/api/packages.html)
- [publint documentation](https://publint.dev/docs/)
- [Are the Types Wrong?](https://arethetypeswrong.github.io/)
