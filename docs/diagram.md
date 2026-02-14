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

## SysML N-Square Diagram (Function-Component Allocation Matrix)

Based on actual Terraform resources (`lxd_network`, `lxd_profile`, `lxd_instance`):

```
╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
║                              N-SQUARE DIAGRAM: Function-Component Traceability                            ║
╠════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣
║                                                                                                            ║
║  Functions (↓) / Components (→) │ GitHub │ Jenkins │ Terraform │ LXD Prov │ LXD Daemon │ LXD Network │ VM  ║
║  ────────────────────────────────────────┼────────┼─────────┼──────────┼──────────┼─────────────┼─────────────┼─────║
║  1. Trigger Release                    │   X    │         │          │          │             │             │      ║
║  2. Run Pipeline                       │        │    X    │          │          │             │             │      ║
║  3. Terraform Init                     │        │         │    X     │          │             │             │      ║
║  4. Terraform Plan                     │        │         │    X     │          │             │             │      ║
║  5. Terraform Apply                    │        │         │    X     │    X     │             │             │      ║
║  6. Create Network (bridge/macvlan)   │        │         │          │    X     │     X       │      X      │      ║
║  7. Create Profile (CPU/RAM/Disk)    │        │         │          │    X     │     X       │             │      ║
║  8. Create VM Instance                │        │         │          │          │     X       │             │  X   ║
║  9. Cloud-init (SSH/K3s bootstrap)   │        │         │          │          │     X       │             │  X   ║
║  10. Run Verification Tests           │        │         │          │          │             │             │  X   ║
║  11. Report Status                    │        │    X    │          │          │             │             │      ║
║  12. Terraform Destroy                 │        │         │    X     │          │             │             │      ║
║                                                                                                            ║
╠════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣
║  Legend: X = implements/owns                                                                          v1.0  ║
╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝
```

### Terraform Resource Mapping

| Resource Type | Function | Description |
|--------------|----------|-------------|
| `lxd_network` | #6 | Creates bridge or macvlan network |
| `lxd_profile` | #7 | Creates profile with CPU, memory, disk, network config |
| `lxd_instance` | #8, #9 | Creates VM and triggers cloud-init for K3s setup |

### Traceability Notes

- **GitHub**: Functions 1, 11 (Trigger Release, Report Status)
- **Jenkins Pipeline**: Functions 2, 11 (Run Pipeline, Report Status)
- **Terraform**: Functions 3, 4, 5, 12 (Init, Plan, Apply, Destroy)
- **LXD Provider**: Functions 5, 6, 7 (Apply, Network, Profile)
- **LXD Daemon**: Functions 6, 7, 8, 9 (Network, Profile, VM, Cloud-init)
- **LXD Network**: Function 6 (Network resource)
- **LXD VM**: Functions 8, 9, 10 (Instance, Cloud-init, Tests)

## SysML Requirements Traceability Matrix (RTM)

```
╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
║                                    REQUIREMENTS TRACEABILITY MATRIX                                           ║
╠════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣
║                                                                                                                ║
║  Requirement ID │ Requirement Description              │ Block/Component            │ Status    │ Test Method      ║
║  ──────────────┼─────────────────────────────────────┼─────────────────────────────┼───────────┼──────────────────║
║  REQ-001       │ Deploy K3s in LXD VMs                │ LXDVirtualMachine          │ Implemented│ terraform apply  ║
║  REQ-002       │ Support bridge networking            │ lxd_network (bridge)       │ Implemented│ terraform apply  ║
║  REQ-003       │ Support macvlan networking           │ lxd_network (macvlan)      │ Implemented│ terraform apply  ║
║  REQ-004       │ Configurable CPU allocation          │ lxd_profile                │ Implemented│ terraform apply  ║
║  REQ-005       │ Configurable memory allocation       │ lxd_profile                │ Implemented│ terraform apply  ║
║  REQ-006       │ Cloud-init for VM bootstrap          │ lxd_instance (user-data)   │ Implemented│ terraform apply  ║
║  REQ-007       │ K3s auto-installation               │ cloud_config               │ Implemented│ VM verification  ║
║  REQ-008       │ SSH access to VMs                   │ cloud_config               │ Implemented│ SSH connectivity ║
║  REQ-009       │ CI/CD pipeline automation           │ JenkinsPipeline           │ Implemented│ Jenkins job      ║
║  REQ-010       │ GitHub webhook trigger              │ GitHubRelease             │ Implemented│ Webhook test     ║
║  REQ-011       │ Terraform state management          │ Terraform                 │ Implemented│ terraform state  ║
║  REQ-012       │ Manual rollback capability          │ Terraform                 │ Implemented│ terraform destroy║
║                                                                                                                ║
╠════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣
║  Status: Implemented | Verified | Pending | Failed                                                         v1.0  ║
╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝
```

### Requirements Allocation

- **REQ-001** → `lxd_instance` (type = "virtual-machine")
- **REQ-002** → `lxd_network` (type = "bridge")
- **REQ-003** → `lxd_network` (type = "macvlan")
- **REQ-004** → `lxd_profile` (config.limits.cpu)
- **REQ-005** → `lxd_profile` (config.limits.memory)
- **REQ-006** → `lxd_profile` (config.user.user-data)
- **REQ-007** → cloud_config (K3s install script)
- **REQ-008** → cloud_config (SSH authorized_keys)
- **REQ-009** → Jenkinsfile
- **REQ-010** → GitHub webhook
- **REQ-011** → Terraform state
- **REQ-012** → terraform destroy

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
