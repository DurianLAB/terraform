# LXD Virtual Machine Infrastructure with Terraform - System Architecture

## SysML Activity Diagram

```
                            ┌─────────────────────┐
                            │    [Start]          │
                            │   GitHub Release    │
                            └──────────┬──────────┘
                                       │
                                       ▼
                            ┌─────────────────────┐
                            │  (Jenkins Pipeline) │
                            │    Run Terraform    │
                            └──────────┬──────────┘
                                       │
                                       ▼
                            ┌─────────────────────┐
                            │  (Terraform Apply)  │
                            │  Provision LXD VMs  │
                            └──────────┬──────────┘
                                       │
                                       ▼
                            ┌─────────────────────┐
                            │  (LXD Daemon)       │
                            │  Creates VMs        │
                            └──────────┬──────────┘
                                       │
                                       ▼
                            ┌─────────────────────┐
                            │  (Run Tests)        │
                            │  Verify Deployment   │
                            └──────────┬──────────┘
                                       │
                              ┌────────┴────────┐
                              │   [Decision]    │
                              │   Tests Pass?   │
                              └────────┬────────┘
                            yes/        \no
                               /         \
                              ▼           ▼
                    ┌───────────┐   ┌───────────┐
                    │ [Action]  │   │ [Action]  │
                    │  Update   │   │  Update   │
                    │  Status:  │   │  Status:  │
                    │    OK     │   │  FAILED   │
                    └─────┬─────┘   └─────┬─────┘
                          │               │
                          │               ▼
                          │     ┌─────────────────┐
                          │     │  (Manual)       │
                          │     │  terraform      │
                          │     │  destroy        │
                          │     └────────┬────────┘
                          │              │
                          └──────┬───────┘
                                 │
                                 ▼
                         ┌───────────────┐
                         │    [End]      │
                         └───────────────┘
```

## SysML Activity Diagram (Mermaid)

```mermaid
graph TB
    Start([Start]) --> A[GitHub Release]
    A --> B[Run Jenkins Pipeline]
    B --> C[Terraform Apply]
    C --> D[Create LXD VMs]
    D --> E[Run Integration Tests]
    E --> D1{Tests Pass?}
    
    D1 -->|yes| F[Update Status: OK]
    D1 -->|no| G[Update Status: FAILED]
    G --> H[Manual terraform destroy]
    
    F --> End([End])
    H --> End
```


## Component Requirements

### LXD Server (Daemon)

| Requirement | Description |
|-------------|-------------|
| **Host** | Linux server (physical/virtual) |
| **LXD Version** | 4.0+ |
| **Port** | 8443 (REST API) |
| **Network** | Accessible by Terraform host |
| **Authentication** | Certificate-based (trust password) |

### Terraform / LXD Provider

| Requirement | Description |
|-------------|-------------|
| **Terraform** | 1.0+ |
| **Provider** | `terraform-lxd/lxd` |
| **Network Access** | Must reach LXD daemon port 8443 |
| **Credentials** | LXD trust certificate |

### Jenkins

| Requirement | Description |
|-------------|-------------|
| **Plugins** | Pipeline, SSH Agent, Terraform, Git |
| **Credentials** | SSH private key, LXD certificates |
| **Webhook** | GitHub webhook trigger on release |
| **Agent** | Docker or SSH agent for running terraform |

## SysML Block Definition Diagram

```
╔══════════════════════════════════════════════════════════════════════════════════╗
║                            SYSML BLOCK DEFINITION                                ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║  ┌─────────────────────┐                                                    ║
║  │    <<block>>        │                                                    ║
║  │   GitHubRelease     │                                                    ║
║  ├─────────────────────┤                                                    ║
║  │ + tag: String       │                                                    ║
║  │ + webhook_trigger   │                                                    ║
║  └──────────┬──────────┘                                                    ║
║             │ triggers (webhook)                                             ║
║             ▼                                                                ║
║  ┌─────────────────────┐                                                    ║
║  │    <<block>>        │                                                    ║
║  │   JenkinsPipeline   │                                                    ║
║  ├─────────────────────┤                                                    ║
║  │ + runTerraform()    │                                                    ║
║  │ + runTests()        │                                                    ║
║  └──────────┬──────────┘                                                    ║
║             │ executes                                                       ║
║             ▼                                                                ║
║  ┌─────────────────────┐     ┌─────────────────────┐                       ║
║  │    <<block>>        │     │    <<block>>        │                       ║
║  │    Terraform        │     │  Terraform LXD      │                       ║
║  │    Configuration    │     │    Provider         │                       ║
║  ├─────────────────────┤     ├─────────────────────┤                       ║
║  │ + provider: LXD     │     │ + endpoint: String  │                       ║
║  │ + lxd_instance      │────▶│ + config: Dict       │                       ║
║  └──────────┬──────────┘     └──────────┬──────────┘                       ║
║             │                             │                                   ║
║             │    REST API                 │ connects                         ║
║             │     (8443)                  ▼                                   ║
║             │                     ┌─────────────────────┐                    ║
║             │                     │    <<block>>        │                    ║
║             └───────────────────▶│    LXCDaemon       │                    ║
║                                   ├─────────────────────┤                    ║
║                                   │ + port: 8443       │                    ║
║                                   │ + certificates     │                    ║
║                                   │ + vms: List        │                    ║
║                                   └──────────┬──────────┘                    ║
║                                              │ manages                         ║
║                                              ▼                                ║
║                                   ┌─────────────────────┐                    ║
║                                   │  <<block>>          │                    ║
║                                   │  LXDVirtualMachine  │                    ║
║                                   ├─────────────────────┤                    ║
║                                   │ + name: String     │                    ║
║                                   │ + image: String    │                    ║
║                                   │ + type: vm         │                    ║
║                                   └─────────────────────┘                    ║
╚══════════════════════════════════════════════════════════════════════════════════╝
```

## Example Jenkinsfile

```groovy
pipeline {
    agent any
    
    triggers {
        GenericTrigger(
            genericVariables: [
                [key: 'REF', value: '$.ref'],
                [key: 'ACTION', value: '$.action']
            ],
            causeString: 'Triggered by GitHub Release',
            token: 'lxc-terraform-pipeline'
        )
    }
    
    stages {
        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }
        
        stage('Terraform Apply') {
            when {
                expression { env.ACTION == 'released' }
            }
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }
        
        stage('Run Tests') {
            steps {
                sh './test-vm.sh'
            }
        }
    }
}
```

## Example Terraform Configuration

```hcl
# LXD Provider Configuration
provider "lxd" {
  address = "https://192.168.1.100:8443"
  cert_file = "./lxd-cert.crt"
  key_file  = "./lxd-key.key"
}

# Virtual Machine Definition
resource "lxd_instance" "k3s_vm" {
  name      = "k3s-server"
  image     = "ubuntu/22.04"
  type      = "virtual-machine"
  ephemeral = false
  profiles  = ["default"]

  wait_for_network = true

  config = {
    "limits.cpu"    = "2"
    "limits.memory" = "4GB"
  }
}
```
