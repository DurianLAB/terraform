# LXC Infrastructure with Terraform - System Architecture

## SysML Block Definition Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        INFRASTRUCTURE DOMAIN                                │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DEPLOYMENT FLOW                                   │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌───────────┐
│   GitHub     │────▶│   Jenkins    │────▶│  Terraform   │────▶│   LXC     │
│   Release    │     │   Pipeline   │     │   Apply     │     │   Client  │
└──────────────┘     └──────────────┘     └──────────────┘     └─────┬─────┘
                                                                       │
                                    ┌──────────────────────────────────┘
                                    │
                                    ▼
                          ┌─────────────────────┐
                          │    LXD Daemon       │
                          │   (Server)          │
                          │  ┌─────────────┐    │
                          │  │  Port 8443  │    │
                          │  └─────────────┘    │
                          └─────────┬──────────┘
                                    │
                                    ▼
                          ┌─────────────────────┐
                          │   LXC Containers   │
                          │  ┌───────────────┐  │
                          │  │ Container 1  │  │
                          │  │ Container 2  │  │
                          │  │ Container N  │  │
                          │  └───────────────┘  │
                           └─────────────────────┘
                                     │
                                     ▼
                           ┌─────────────────────┐
                           │   Tests / Verify    │
                           └──────────┬──────────┘
                                      │
                     ┌───────────────┴───────────────┐
                     │                               │
                     ▼                               ▼
              ┌─────────────┐                 ┌─────────────┐
              │   Success   │                 │   Failure   │
              └──────┬──────┘                 └──────┬──────┘
                     │                               │
                     ▼                               ▼
              ┌─────────────┐                 ┌─────────────┐
              │  GitHub     │                 │  GitHub     │
              │  Status: OK │                 │  Status:    │
              └─────────────┘                 │  FAILED     │
                                              └──────┬──────┘
                                                     │
                                                     ▼
                                              ┌─────────────┐
                                              │ Manual       │
                                              │ terraform    │
                                              │ destroy      │
                                              └─────────────┘
```

## SysML Package Diagram

```mermaid
graph TB
    subgraph "GitHub"
        A[Release v1.0] --> B[Jenkins Pipeline]
        F[Status: FAILED] --> A
        G[Status: OK] --> A
    end
    
    subgraph "IaC Layer"
        B --> C[Terraform]
        C --> D[LXD Provider]
    end
    
    subgraph "LXC Infrastructure"
        D -->|REST API 8443| E[LXD Daemon]
        E --> F1[LXC Containers]
    end
    
    subgraph "Validation"
        F1 --> H[Integration Tests]
        H -->|pass| G
        H -->|fail| F
    end
```

## SysML Block Definition (Detailed)

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                            SYSML BLOCK DEFINITION                            ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║  ┌─────────────────────┐                                                    ║
║  │    <<block>>        │                                                    ║
║  │    GitHubRelease    │                                                    ║
║  ├─────────────────────┤                                                    ║
║  │ + tag: String       │                                                    ║
║  │ + webhook_trigger  │                                                    ║
║  └──────────┬──────────┘                                                    ║
║             │ triggers (webhook)                                            ║
║             ▼                                                                ║
║  ┌─────────────────────┐                                                    ║
║  │    <<block>>        │                                                    ║
║  │   JenkinsPipeline   │                                                    ║
║  ├─────────────────────┤                                                    ║
║  │ + runTerraform()    │                                                    ║
║  │ + runAnsible()      │                                                    ║
║  │ + runTests()        │                                                    ║
║  └──────────┬──────────┘                                                    ║
║             │ executes                                                       ║
║             ▼                                                                ║
║  ┌─────────────────────┐     ┌─────────────────────┐                       ║
║  │    <<block>>        │     │    <<block>>        │                       ║
║  │    Terraform        │     │  Terraform LXD      │                       ║
║  │    Configuration    │     │    Provider         │                       ║
║  ├─────────────────────┤     ├─────────────────────┤                       ║
║  │ + provider: LXC     │     │ + endpoint: String  │                       ║
║  │ + lxc_container     │────▶│ + config: Dict      │                       ║
║  └──────────┬──────────┘     └──────────┬──────────┘                       ║
║             │                             │                                   ║
║             │    REST API                 │ connects                         ║
║             │     (8443)                  ▼                                   ║
║             │                     ┌─────────────────────┐                    ║
║             │                     │    <<block>>        │                    ║
║             └───────────────────▶│    LXDDaemon       │                    ║
║                                   ├─────────────────────┤                    ║
║                                   │ + port: 8443       │                    ║
║                                   │ + certificates     │                    ║
║                                   │ + containers: List  │                    ║
║                                   └──────────┬──────────┘                    ║
║                                              │ manages                         ║
║                                              ▼                                ║
║                                   ┌─────────────────────┐                    ║
║                                   │  <<block>>          │                    ║
║                                   │  LXCContainer       │                    ║
║                                   ├─────────────────────┤                    ║
║                                   │ + name: String      │                    ║
║                                   │ + image: String     │                    ║
║                                   │ + ephemeral: Bool  │                    ║
║                                   └─────────────────────┘                    ║
╚═══════════════════════════════════════════════════════════════════════════════╝
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

### LXC Client / Terraform

| Requirement | Description |
|-------------|-------------|
| **Terraform** | 1.0+ |
| **Provider** | `terraform-provider-lxc` or `terraform-provider-lxd` |
| **Network Access** | Must reach LXD daemon port 8443 |
| **Credentials** | LXD trust certificate |

### Jenkins

| Requirement | Description |
|-------------|-------------|
| **Plugins** | Pipeline, SSH Agent, Terraform, Git |
| **Credentials** | SSH private key, LXD certificates |
| **Webhook** | GitHub/GitLab webhook trigger on release |
| **Agent** | Docker or SSH agent for running terraform |

## Connection Flow Sequence

```
┌─────────┐     ┌──────────┐     ┌───────────┐     ┌────────┐     ┌─────────┐
│ GitHub  │────▶│  Jenkins │────▶│ Terraform │────▶│  LXD   │────▶│  Test   │
│ Release │     │ Pipeline │     │   Apply   │     │  API   │     │ Verify  │
└─────────┘     └──────────┘     └───────────┘     └────────┘     └────┬────┘
      ▲                                                                     │
      │                                                                     │
      │                    ┌──────────────────────────────────────────────┘
      │                    │
      │                    ▼                Failure Path
      │              ┌─────────────┐      (manual cleanup)
      │              │ GitHub      │◀──── terraform destroy
      │              │ Status:     │
      │              │ FAILED      │
      │              └──────┬──────┘
      │                     │
      └─────────────────────┘
           Notification
```

## Error Handling

On failure, the pipeline:
1. Reports status back to GitHub (FAILED)
2. Does NOT auto-rollback (containers remain for debugging)
3. Manual cleanup required: `terraform destroy`

This approach allows inspection of failed containers for debugging purposes.

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
                sh './test-container.sh'
            }
        }
    }
}
```

## Example Terraform Configuration

```hcl
# LXC Provider Configuration
provider "lxc" {
  lxc_url = "https://192.168.1.100:8443"
  lxc_cert = "./lxd-cert.crt"
  lxc_key  = "./lxd-key.key"
}

# Container Definition
resource "lxc_container" "jenkins" {
  name        = "jenkins-server"
  image       = "ubuntu/22.04"
  ephemeral   = false
  start       = true

  config = {
    "security.nesting" = "true"
    "linux.kernel_modules" = "overlay,nf_conntrack"
  }

  devices = {
    root = {
      path = "/"
      type = "disk"
    }
  }
}
```
