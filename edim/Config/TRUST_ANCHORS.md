# Trust anchors

The wallet builds its trust list from DER-encoded root certificates bundled in
`edim/edim/Resources/`. These certificates are supplied per deployment and are
not part of the source tree.

Without them the app still builds, but logs
`Trust list incomplete: loaded N of M anchors` at runtime, and issuance and
presentation will fail until the anchors are supplied.

## Expected filenames

`TrustAnchors.swift` resolves anchors by filename. The set depends on the build
target:

| File | production (`edim`) | development (`edim-dev`) |
| --- | :---: | :---: |
| `issuer_ca.der` | ✅ | ✅ |
| `verifier_ca_prod.der` | ✅ | ✅ |
| `pidissuerca02_eu.der` | ✅ | ✅ |
| `reader_ca.der` | ✅ | ✅ |
| `verifier_ca_dev.der` | — | ✅ |
| `eudi_pid_issuer_ut.der` | — | ✅ |
| `pidissuerca02_ut.der` | — | ✅ |

The bottom three are test/conformance anchors and are deliberately **excluded
from production builds**, so that a test issuer can never be trusted by a
shipping wallet. That split is enforced in code via `AppEnvironment`, not by
which files happen to be present.

## Where to obtain them

* `pidissuerca02_eu.der`, `pidissuerca02_ut.der`, `eudi_pid_issuer_ut.der` and
  `issuer_ca.der` are certificates of the **EUDI Wallet Reference
  Implementation**, published by the European Commission. `pidissuerca02_ut.der`
  is also present, byte-identical, in this repository at
  `eudi-lib-ios-wallet-kit-0.50.0/Tests/EudiWalletKitTests/Resources/`.
* `verifier_ca_prod.der`, `verifier_ca_dev.der` and `reader_ca.der` are
  operator-specific and are provided by the wallet provider for a given
  deployment.

## Running your own deployment

If you are standing up an independent deployment, replace the operator-specific
anchors with your own CA certificates under the same filenames. Nothing in the
source assumes a particular issuer; only the filenames are fixed.

## Format

DER, not PEM. To convert:

```sh
openssl x509 -in my_ca.pem -outform DER -out my_ca.der
```

To inspect what an anchor actually contains:

```sh
openssl x509 -in edim/edim/Resources/reader_ca.der -inform DER -noout -subject -ext subjectAltName
```
