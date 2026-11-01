# Talos Single

Talos single-node kubernetes cluster managed with TOPF.

## Prerequisites

Before provisioning the cluster, ensure the following tools are installed
on the management workstation:

- `talosctl` - Talos management CLI.
- `kubectl` - Kubernetes management CLI.
- `topf` - Talos cluster orchestrator.
- `sops` - Secrets encryption and decryption.
- `age` - Encryption key management.

In addition, ensure the following prerequisites are met:

- A machine booted into Talos Linux maintenance mode.
- A DHCP reservation pointing to the machine's network interface MAC address.
- Network connectivity between the management workstation and the Talos machine.

## Provisioning

Generate the cluster secrets; they will be automatically encrypted with SOPS
using age:

```bash
topf secrets
```

Apply the configuration and bootstrap the cluster:

```bash
topf apply --auto-bootstrap
```

## Credentials

Generate the cluster credentials:

```bash
topf kubeconfig > secrets/kubeconfig
topf talosconfig > secrets/talosconfig
```

## Secrets

Sensitive files are stored under `secrets/` and encrypted with SOPS using age.

### Editor configuration

Configure VS Code as the SOPS editor:

```bash
export SOPS_EDITOR="code --wait"
```

Add this to your shell profile (`~/.bashrc` or `~/.zshrc`) to make it persistent.

### Encryption

Encrypt files before committing:

```bash
find secrets -type f -exec sops --encrypt --in-place {} \;
```

### Decryption

Decrypt a file to stdout:

```bash
sops --decrypt secrets/secrets.yaml
```

Decrypt all files in place when necessary:

```bash
find secrets -type f -exec sops --decrypt --in-place {} \;
```

### Editing

Edit encrypted files directly with SOPS:

```bash
sops secrets/secrets.yaml
```

SOPS automatically decrypts the file, opens it in VS Code, and re-encrypts
it when the editor is closed.
