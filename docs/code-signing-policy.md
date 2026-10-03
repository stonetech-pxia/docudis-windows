# Code signing policy

Windows releases of Docudis Desktop are not code signed yet. The project is preparing to apply to [SignPath Foundation](https://signpath.org) for free code signing of open-source software; this page will name the signing provider once that is in place. Until then, check each download against its SHA-256 and build provenance attestation (see below).

## What is built and how

- Every release is built by [GitHub Actions](../.github/workflows/windows.yml) from a tagged commit of this repository, on GitHub's runners: the native libraries at the revisions pinned in [tool/native.lock.json](../tool/native.lock.json), the app, and the NER model pinned by SHA-256. Nothing is built on a maintainer's machine.
- Each release zip comes with its SHA-256 and a build provenance attestation, which shows that the file was built by that workflow from that commit:

  ```
  gh attestation verify docudis-<version>-windows-x64.zip -R stonetech-pxia/docudis-desktop
  ```

- Releases are created as drafts and published by hand after review.

## What will be signed

Only binaries built from source code this team maintains:

- `docudis.exe`, from this repository;
- `docudis_capi.dll`, from [docudis-core](https://github.com/stonetech-pxia/docudis-core);
- `docudis_ner_capi.dll`, from [docudis-ner](https://github.com/stonetech-pxia/docudis-ner).

Binaries of upstream open-source projects ship unsigned inside the package: ONNX Runtime (built from Microsoft's source without telemetry), the Flutter engine and plugins, PDFium and the Visual C++ runtime.

## Team roles

The project has one maintainer, who holds all three roles:

- Committers and reviewers: [stonetech-pxia](https://github.com/stonetech-pxia)
- Approvers: [stonetech-pxia](https://github.com/stonetech-pxia)

The repository does not accept pull requests for now (see [CONTRIBUTING.md](../CONTRIBUTING.md)). Every change is committed by the maintainer, and every release is approved by the maintainer.

## Privacy policy

This program will not transfer any information to other networked systems unless specifically requested by the user or the person installing or operating it.

The only network action the app can take is opening a link (privacy policy, contact) in the user's browser when the user clicks it. No third-party component it bundles transfers data either. [No network, no upload](network-audit.md) describes what this covers, how it is enforced and how it is checked, with the results.
