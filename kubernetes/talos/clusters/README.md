# Talos Cluster

Talos kubernetes cluster managed with TOPF.

## Overview

This document describes the prerequisites, provisioning process, cluster access
configuration, secrets management, and hardware-specific configuration.

TOPF is the orchestration tool used to manage the Talos cluster lifecycle.
It automates cluster secret generation, configuration deployment, and Kubernetes
bootstrapping.

One of its main purposes is to address Talos configuration templating limitations
by providing an abstraction for managing and applying configurations dynamically,
as Talos does not natively support configuration templating, making static patches
difficult to scale and maintain as cluster complexity grows.

## Prerequisites

Before provisioning the cluster, ensure the following tools are installed
on the management workstation:

- `talosctl` - Talos management CLI.
- `kubectl` - Kubernetes management CLI.
- `topf` - Talos cluster orchestrator.
- `sops` - Secrets encryption and decryption.
- `age` - Encryption key management.

The following infrastructure requirements must also be met for each node in the
cluster:

- SecureBoot is enabled in the UEFI firmware; see [SecureBoot](#secureboot) section.
- The node is booted into Talos maintenance mode.
- A DHCP reservation is configured for the node's network interface MAC address.
- Network connectivity between the management workstation and the Talos node.

## CLuster provisioning

Generate the cluster secrets; they will be automatically encrypted with SOPS
using age:

```bash
topf secrets
```

Apply the configuration and bootstrap the cluster:

```bash
topf apply --auto-bootstrap
```

## Cluster access

Talos and Kubernetes provide separate configuration files for managing the
cluster. Generate the cluster credentials and store them under `secrets/`:

```bash
topf kubeconfig > secrets/kubeconfig
topf talosconfig > secrets/talosconfig
```

## Secrets

Sensitive files are stored under `secrets/` and encrypted with SOPS using age.

SOPS provides transparent encryption and decryption, allowing encrypted files
to be edited without manually managing their encryption state.

### Editor configuration

Configure VS Code as the SOPS editor:

```bash
export SOPS_EDITOR="code --wait"
```

Add this to your shell profile (`~/.bashrc` or `~/.zshrc`) to make it persistent.

### Editing

Edit encrypted files directly with SOPS:

```bash
sops secrets/secrets.yaml
```

SOPS automatically decrypts the file, opens it in VS Code, and re-encrypts
it when the editor is closed.

### Encryption

Encrypt files before committing:

```bash
find secrets -type f -exec sops --encrypt --in-place {} \;
```

This operation is intended for initially encrypting plaintext files. Only use
it on files that are not already encrypted.

### Decryption

Decrypt a file to stdout:

```bash
sops --decrypt secrets/secrets.yaml
```

Decrypt all files in place when necessary:

```bash
find secrets -type f -exec sops --decrypt --in-place {} \;
```

## Hardware configuration

This section documents hardware-specific configuration required before installing
Talos.

### SecureBoot

SecureBoot must be enabled in the node's UEFI firmware to protect the Talos
boot process.

Talos provides SecureBoot-enabled installation images through the
[Sidero Labs Image Factory](https://factory.talos.dev/). However, some hardware
does not trust the signing certificate used by these images by default.

In such cases, the Sidero Labs SecureBoot signing keys must be enrolled in the
UEFI firmware before Talos can boot successfully.

#### HP EliteDesk 800 G-series

On HP EliteDesk 800 G-series nodes, the default UEFI configuration does not
trust the SecureBoot certificate used by Sidero Labs.

Attempting to boot a SecureBoot-enabled Talos image may result in the following
error:

```text
Selected boot image did not authenticate
```

The following procedure enrolls the required signing keys in the UEFI firmware.
It is based on:

[Enabling Talos OS SecureBoot on HP EliteDesk 800 G5](https://www.oct8l.com/posts/2025/46/enabling-talos-os-secureboot-on-hp-elitedesk-800-g5/).

##### Disable SecureBoot keys protection

1. Reboot the node and press `Esc` repeatedly to enter the HP Startup Menu.
2. Enter BIOS Setup.
3. Navigate to `Security -> BIOS Sure Start`.
4. Disable `Sure Start Secure Boot Keys Protection`.
5. Save the changes and reboot.
6. When prompted, enter the PIN displayed on the screen to confirm the change.

##### Enable custom SecureBoot keys

1. Enter BIOS Setup again.
2. Navigate to `Advanced -> Secure Boot Configuration`.
3. Enable `Import Custom Secure Boot Keys`.
4. Save the changes and reboot.
5. Enter the confirmation PIN when prompted.

The firmware may display an error indicating that SecureBoot keys could not be
imported from USB or the HP directory. This is expected in this procedure;
continue booting.

##### Enroll Talos SecureBoot keys

After the reboot, the Talos installation media should boot.

1. Select the following option from the Talos boot menu:

   ```text
   Enroll Secure Boot keys: auto
   ```

2. Confirm the operation and allow the enrollment process to complete.
3. The node will reboot automatically.
4. Boot the Talos installation media again if necessary.

Verify that SecureBoot is enabled by checking the status displayed in the Talos
boot screen:

```text
SECUREBOOT: True
```

The node should now trust the signing keys required to boot Talos.

##### Re-enable BIOS SecureBoot protection

After successfully enrolling the keys and installing Talos, restore the
HP BIOS protection:

1. Reboot the node and enter BIOS Setup.
2. Navigate to `Security -> BIOS Sure Start`.
3. Re-enable `Sure Start Secure Boot Keys Protection`.
4. Save the changes and reboot.

This restores the firmware protection while retaining the enrolled SecureBoot
keys.
