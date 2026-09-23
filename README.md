# Digimaks — EU Digital Identity Wallet (iOS)

**Digimaks** is an **[EU Digital Identity Wallet (EUDIW)](https://ec.europa.eu/digital-building-blocks/sites/display/EUDIGITALIDENTITYWALLET/EU+Digital+Identity+Wallet+Home)**
application for iOS, continuing the work of the
**[NOBID Consortium](https://www.nobidconsortium.com/)**.

It lets a person hold issued digital credentials on their device and present them —
selectively, under their own control — to public and private relying parties, in line
with the [eIDAS 2.0 Regulation (EU) 2024/1183](https://eur-lex.europa.eu/eli/reg/2024/1183/oj).

It bundles and uses the **Digimaks WebApp** (built on the
[LX/UI platform](https://github.com/wntrtech/lx-ui)) for its user interface, and aims for
feature parity with the **Digimaks Android app**.

### Background: continuation of the NOBID Consortium wallet

Digimaks is the **direct continuation of the EUDI Wallet application developed under the
[NOBID Consortium](https://www.nobidconsortium.com/)** (the Nordic-Baltic eID Project) —
one of the EU Large Scale Pilots for the European Digital Identity Wallet, in which
Nordic and Baltic partners jointly piloted cross-border wallet issuance and use.

The codebase began life as that NOBID EUDIW pilot application and has since been carried
forward, hardened and released publicly under the name **Digimaks**. The consortium
lineage is still visible throughout the source, and readers should expect to meet it:

| You will see | What it means |
| ------------ | ------------- |
| `Digimaks` / `digimaks://` | The current product name and its deeplink scheme |
| `edim` (targets, folders, `@edim/mobile-ui`) | The internal codename used throughout the code — **it refers to this same app** |
| `NobidShareExtension.lv://` | A **legacy NOBID deeplink scheme, still registered** for backwards compatibility (see [§8](#8-deeplink-schemes)) |
| `NOBID`, `EUDIW` in code and documentation | References to the NOBID Consortium phase this app grew out of |

## Contents

* [1. Prerequisites](#1-prerequisites)
* [2. Cloning the Project](#2-cloning-the-project)
* [3. Configuring the App](#3-configuring-the-app)
* [4. Initializing the WebView (Vue) Application](#4-initializing-the-webview-vue-application)
* [5. Opening and Running the Project in Xcode](#5-opening-and-running-the-project-in-xcode)
* [6. Building Release Version](#6-building-release-version)
* [7. Module Structure](#7-module-structure)
* [8. Deeplink Schemes](#8-deeplink-schemes)
* [9. Additional Information](#9-additional-information)
* [References](#references)

---

## 1. Prerequisites

To compile and run the project successfully, ensure you have:

* **macOS** (latest stable version recommended)
* **Xcode** (latest stable version)
* **Node.js** + **pnpm** (for building the WebView Vue app)

Install `pnpm` globally:

```bash
npm install -g pnpm
```

---

## 2. Cloning the Project

```bash
git clone https://github.com/digimaks/mobile-ios.git
cd mobile-ios
```

---

## 3. Configuring the App

The app reads its backend host, OAuth client IDs and wallet settings from four
property lists, which you supply for your own environment.

Create them from the bundled templates:

```bash
./scripts/setup-config.sh
```

This copies `edim/Config/templates/*` into place (existing files are never
overwritten) and creates `edim/Config/Local.xcconfig` for code signing.

Then edit the generated files and replace the `example.com` placeholders:

| File | Contains |
| --- | --- |
| `edim/edim/API/Backend-Edim.plist` | Backend host + API endpoint paths |
| `edim/edim/API/Local communication/Bases/Base-Prod.plist` | Production host + `apiClientID` |
| `edim/edim/API/Local communication/Bases/Base-Dev.plist` | Development host + `apiClientID` |
| `edim/edim/Resources/WalletInfo-Edim.plist` | OpenID4VCI client ID, issuer path, redirect URI |
| `edim/Config/Local.xcconfig` | `EDIM_DEVELOPMENT_TEAM` — your Apple Developer Team ID |

If you use Firebase, also add your own `edim/edim/GoogleService-Info.plist`.

### 3.1. Trust anchors

The wallet's trust list is built from DER-encoded root certificates in
`edim/edim/Resources/`.

Unlike the property lists above these cannot be templated — they are real
certificates and must be supplied for your environment. `setup-config.sh`
reports which are missing; see **[edim/Config/TRUST_ANCHORS.md](edim/Config/TRUST_ANCHORS.md)**
for the expected filenames, which of them each build target requires, and where
the publicly available EUDI reference certificates can be obtained.

> Without anchors the app still builds and launches, but logs
> `Trust list incomplete: loaded N of M anchors` and credential issuance and
> presentation will fail.

---

## 4. Initializing the WebView (Vue) Application

The app includes an embedded Vue.js application used in WebView, located at:

```
edim/
```

To initialize and build it:

```bash
cd edim
pnpm install
pnpm run build
```

The output will be included in the app bundle and loaded via WebView.

---

## 5. Opening and Running the Project in Xcode


1. Open the `edim.xcodeproj` file in Xcode.
2. Select the scheme: `edim-dev` for development, `edim` for production.
3. Choose a target device or simulator.
4. Press `Cmd + R` or click ▶️ to run.

Ensure that:

* Signing is configured (certificates and provisioning profiles)
* Bundle IDs are adjusted for your environment if needed

---

## 6. Building Release Version

To create a release build:

1. Select the `Release` scheme.
2. Go to **Product > Archive** in Xcode.
3. Use the Organizer to export via App Store or TestFlight.

For automated CI/CD, use `.xcodebuild` with the appropriate environment and secrets for signing.

---

## 7. Module Structure

The repository is laid out as follows. Note that the directories use the internal
codename `edim` rather than the product name *Digimaks* — see
[Background](#background-continuation-of-the-nobid-consortium-wallet).

| Path                    | Description                                      |
| ----------------------- | ------------------------------------------------ |
| `edim/edim.xcodeproj`   | Xcode project                                    |
| `edim/edim/`            | iOS app source (Swift)                           |
| `edim/src/`             | WebView UI source (Vue)                          |
| `edim/dist/`            | Built WebView output, bundled into the app       |
| `edim/Config/`          | Build configuration, templates, trust-anchor docs |
| `edim/SigningFileExtension/` | iOS document signing extension              |
| `scripts/`              | Developer setup scripts                          |

Within the Swift source (`edim/edim/`):

| Module/Folder                   | Description                                 |
| ------------------------------- | ------------------------------------------- |
| `API/`, `Services/`, `Helpers/` | Business logic, networking, and utilities   |
| `CommonicationHelper/`          | Native ↔ WebView interaction handler        |
| `Destination interfaces/`       | Navigation targets and screen logic         |
| `Realm/`, `Models/`, `Session/` | Local data, DB models, and session state    |
| `Security layer/`               | Device checks, biometrics, attestation      |
| `UI/`, `Wallet/`                | Visual components and credential management |
| `Extensions/`, `Resources/`     | Swift extensions and bundled assets         |

The Xcode project builds three targets:

| Target                 | Product          | Purpose                                |
| ---------------------- | ---------------- | -------------------------------------- |
| `edim`                 | **Digimaks**     | Production app                         |
| `edim-dev`             | **Digimaks-DEV** | Development build (test trust anchors) |
| `SigningFileExtension` | —                | Document signing extension             |

---

## 8. Deeplink Schemes

The following deeplink URL schemes are registered by the app in `Info.plist`
(`CFBundleURLTypes`):

| Deeplink URI                  | `CFBundleURLName`              | Description                                                  |
|-------------------------------|--------------------------------|--------------------------------------------------------------|
| `digimaks://`                 | `lv.zzdats.edim`               | Primary Digimaks scheme — opens the app / resumes a flow      |
| `NobidShareExtension.lv://`   | `lv.zzdats.share`              | **Legacy NOBID scheme**, retained — Share Sheet / file signing |
| `openid-credential-offer://`  | `lv.zzdats.credential.offer`   | OpenID4VCI credential offer (starts issuance)                 |
| `openid-vp://`                | `lv.dativa.issuing.deeplink`   | OpenID4VP presentation request                                |
| `openid4vp://`                | `lv.dativa.issuing.new.deeplink` | OpenID4VP presentation request (current scheme)             |


The app additionally declares `LSApplicationQueriesSchemes` so it can detect companion
apps it may need to hand off to — `eparakstsid`, `eparakstsid-demo`, `openid-vp`, `openid4vp` and `digimaks`.

---

## 9. Additional Information

### 9.1. WebView Frontend (Vue)

A lightweight Vue.js app is used for frontend rendering inside WebView. The built output is stored in `dist/` and bundled inside the app.

### 9.2. Swift Package Dependencies

The project uses Swift Package Manager for modular SDKs:

* `eudi-lib-ios-wallet-kit` – Wallet core functionality
* `eudi-lib-ios-siop-openid4vp` – OpenID4VP and SIOP logic
* Other packages: `Moya`, `QRCodeScannerPackage`, `KeychainWrapperPackage`, `realm-swift`, etc.

These are resolved automatically by Xcode on project open.

### 9.3. Code Signing

Code signing and entitlements are managed via:

* `Info.plist`, `*.entitlements`
* Local provisioning profiles or CI/CD environment

---

## References

* [Wallet Core SDK (iOS)](https://github.com/eu-digital-identity-wallet/eudi-lib-ios-wallet-kit)
* [OWASP MASVS](https://mas.owasp.org/MASVS/)
* [Apple Developer – App Distribution](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)
