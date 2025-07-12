# Renovate Setup Script

## Step 1: Create Personal Access Token

**You need to do this manually in your browser:**

1. Go to: https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Give it a name like "Renovate Bot"
4. Set expiration to 1 year
5. Select these scopes:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `workflow` (Update GitHub Action workflows)
6. Click "Generate token"
7. **COPY THE TOKEN** (you won't see it again!)

## Step 2: Add Token to Repository Secrets

**You need to do this manually in your browser:**

1. Go to: https://github.com/mhwilkes/ombra-labops/settings/secrets/actions
2. Click "New repository secret"
3. Name: `RENOVATE_TOKEN`
4. Value: Paste the token from Step 1
5. Click "Add secret"

## Step 3: Test the Setup

Once you've added the secret, you can manually trigger the Renovate workflow:

1. Go to: https://github.com/mhwilkes/ombra-labops/actions/workflows/renovate.yml
2. Click "Run workflow"
3. Select "debug" log level for the first run
4. Click "Run workflow"

## What Happens Next

After the first run:
- Renovate will create a "Dependency Dashboard" issue
- It will scan your ArgoCD applications for updates
- Pull requests will be created for available updates
- You'll get notifications for any updates requiring approval

## Troubleshooting

If the workflow fails:
1. Check that the `RENOVATE_TOKEN` secret is set correctly
2. Verify the token has the right permissions
3. Look at the workflow logs for specific error messages

The token needs these permissions:
- `repo` - To read your repository and create pull requests
- `workflow` - To update GitHub Actions workflows if needed
