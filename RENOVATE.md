# Renovate Bot Configuration

This repository uses [Renovate](https://docs.renovatebot.com/) to automatically keep dependencies up to date across the lab operations cluster.

## What Renovate Monitors

Renovate is configured to monitor and update:

### Container Images

- **Media Services**: Plex, Radarr, Sonarr, Bazarr, Prowlarr, Overseerr, Tautulli, qBittorrent, SABnzbd, Maintainerr
- **Search & Analytics**: Elasticsearch/OpenSearch
- **Infrastructure**: ArgoCD, cert-manager, MetalLB, NGINX, Rook-Ceph

### Helm Charts

- BJW-S App Template charts
- Official Helm charts from various repositories
- Custom chart configurations in ArgoCD Applications

## Update Strategy

### Automatic Updates

- **Patch and Minor versions** for container images are auto-merged
- **Security vulnerabilities** are immediately updated
- Updates are scheduled during off-peak hours (after 10pm weekdays, weekends)

### Manual Approval Required

- **Major version updates** for all components
- **All Helm chart updates** (safer for infrastructure changes)
- Updates requiring manual approval appear in the Dependency Dashboard

## Schedule

- **Regular scans**: Every 4 hours via GitHub Actions
- **Patch/Minor updates**: Automatically during off-peak hours
- **Major updates**: Sundays only, with manual approval required
- **Security updates**: Immediately when detected

## Rate Limiting

- Maximum 3 concurrent pull requests
- Maximum 2 pull requests per hour
- Prevents overwhelming the repository with updates

## GitHub Secrets Required

To use this Renovate configuration, you need to create a Personal Access Token and add it as a repository secret:

### Required Secret

- `RENOVATE_TOKEN` - GitHub Personal Access Token with the following permissions:
  - `repo` (Full control of private repositories)
  - `workflow` (Update GitHub Action workflows)

### How to Create the PAT

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Set expiration (recommend 1 year)
4. Select these scopes:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `workflow` (Update GitHub Action workflows)
5. Generate token and copy it

### How to Add the Secret

1. Go to your repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `RENOVATE_TOKEN`
4. Value: Paste your Personal Access Token
5. Click "Add secret"

## Configuration Files

- `renovate.json` - Main Renovate configuration
- `.github/workflows/renovate.yml` - GitHub Actions workflow

## Dependency Dashboard

Renovate creates and maintains a "Dependency Dashboard" issue in your repository that shows:

- Pending updates awaiting approval
- Failed update attempts
- Configuration errors
- Current dependency status

## Monitoring Updates

1. Check the Dependency Dashboard issue for pending updates
2. Review pull requests created by Renovate
3. Monitor ArgoCD for successful deployments after merges
4. Watch for any failing applications after updates

## Customizing Updates

To modify how Renovate handles specific dependencies:

1. Edit the `packageRules` section in `renovate.json`
2. Add new regex patterns for custom image detection
3. Adjust schedules or automerge settings as needed

## Disabling Renovate

To temporarily disable Renovate:

- Disable the GitHub Actions workflow
- Or add `"enabled": false` to `renovate.json`
