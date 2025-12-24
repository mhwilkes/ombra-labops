# Lefthook Git Hooks Documentation

Lefthook is a fast and powerful git hooks manager that runs validation and linting automatically before commits and pushes.

## Overview

Lefthook ensures code quality by running automated checks:
- **Pre-commit hooks**: Run on every commit (fast checks)
- **Pre-push hooks**: Run before pushing (slower, comprehensive checks)

## Configuration

The lefthook configuration is in [.lefthook.yml](../.lefthook.yml) at the repository root.

### Pre-commit Hooks

These hooks run automatically when you commit changes:

1. **terraform-fmt**: Checks Terraform formatting
   - Runs on `.tf` files
   - Auto-fixes formatting issues
   - Uses `terraform fmt -check`

2. **terraform-lint**: Lints Terraform code
   - Runs on `.tf` files
   - Uses `tflint`
   - Catches errors and best practices violations

3. **yaml-lint**: Lints YAML files
   - Runs on `.yaml` and `.yml` files
   - Uses `yamllint`
   - Validates syntax and style

4. **shellcheck**: Lints shell scripts
   - Runs on `.sh` files
   - Uses `shellcheck`
   - Catches shell script issues

### Pre-push Hooks

These hooks run automatically before pushing to remote:

1. **terraform-validate**: Validates Terraform configuration
   - Runs if Terraform files changed
   - Uses `terraform validate`
   - Ensures configuration is valid

2. **checkov-scan**: Security scanning
   - Runs if Terraform or Kubernetes files changed
   - Uses `checkov`
   - Scans for security misconfigurations
   - Supports Terraform and Kubernetes frameworks

## Usage

### Automatic Execution

Hooks run automatically:
- **Pre-commit**: When you run `git commit`
- **Pre-push**: When you run `git push`

If a hook fails, the commit or push is blocked until issues are fixed.

### Manual Execution

Run hooks manually:

```bash
# Run all pre-commit hooks
lefthook run pre-commit

# Run all pre-push hooks
lefthook run pre-push

# Run specific hook
lefthook run pre-commit terraform-fmt

# Run hooks with alias
hooks-run
hooks run pre-commit
```

### Skip Hooks (Not Recommended)

Skip hooks in special cases:

```bash
# Skip pre-commit hooks
git commit --no-verify

# Skip pre-push hooks
git push --no-verify
```

**Warning**: Only skip hooks when absolutely necessary. Hooks ensure code quality.

## Hook Details

### terraform-fmt

**Purpose**: Ensure Terraform files are properly formatted.

**Command**: `terraform fmt -check -recursive`

**Auto-fix**: Yes (via `stage_fixed: true`)

**Example Output**:
```
terraform-fmt: ✓ All files formatted correctly
```

**If Failed**: Run `terraform fmt -recursive` to fix formatting.

### terraform-lint

**Purpose**: Catch Terraform errors and best practices violations.

**Command**: `tflint {staged_files}`

**Configuration**: See [.tflint.hcl](../.tflint.hcl)

**Example Output**:
```
terraform-lint: ✓ No issues found
```

**If Failed**: Fix issues reported by tflint. See [TOOLS.md](TOOLS.md#tflint) for details.

### yaml-lint

**Purpose**: Validate YAML syntax and style.

**Command**: `yamllint {staged_files}`

**Configuration**: See [.yamllint](../.yamllint)

**Example Output**:
```
yaml-lint: ✓ All YAML files valid
```

**If Failed**: Fix YAML syntax errors. See [TOOLS.md](TOOLS.md#yamllint) for details.

### shellcheck

**Purpose**: Catch shell script issues.

**Command**: `shellcheck {staged_files}`

**Example Output**:
```
shellcheck: ✓ No issues found
```

**If Failed**: Fix shell script issues. See [TOOLS.md](TOOLS.md#shellcheck) for details.

### terraform-validate

**Purpose**: Validate Terraform configuration is correct.

**Command**: `terraform validate`

**Runs**: Only if Terraform files changed

**Example Output**:
```
terraform-validate: ✓ Configuration is valid
```

**If Failed**: Fix Terraform configuration errors. Run `terraform validate` manually for details.

### checkov-scan

**Purpose**: Scan for security misconfigurations.

**Command**: `checkov --directory . --framework terraform --framework kubernetes --quiet`

**Runs**: Only if Terraform or Kubernetes files changed

**Configuration**: See [.checkov.yaml](../.checkov.yaml)

**Example Output**:
```
checkov-scan: ✓ No security issues found
```

**If Failed**: Review and fix security issues. See [TOOLS.md](TOOLS.md#checkov) for details.

## Troubleshooting

### Hooks Not Running

If hooks don't run automatically:

```bash
# Reinstall hooks
lefthook install

# Verify installation
lefthook version
```

### Hook Fails Unexpectedly

1. **Check tool availability**:
   ```bash
   command -v terraform && echo "Installed" || echo "Not installed"
   command -v tflint && echo "Installed" || echo "Not installed"
   command -v yamllint && echo "Installed" || echo "Not installed"
   command -v shellcheck && echo "Installed" || echo "Not installed"
   command -v checkov && echo "Installed" || echo "Not installed"
   ```

2. **Run hook manually** to see detailed output:
   ```bash
   lefthook run pre-commit terraform-lint
   ```

3. **Check configuration files**:
   - [.lefthook.yml](../.lefthook.yml) - Hook configuration
   - [.tflint.hcl](../.tflint.hcl) - Terraform linting rules
   - [.yamllint](../.yamllint) - YAML linting rules
   - [.checkov.yaml](../.checkov.yaml) - Security scanning rules

### Hook Takes Too Long

Pre-push hooks (especially checkov) can be slow:

- **Option 1**: Run hooks manually before pushing:
  ```bash
  hooks-run
  git push
  ```

- **Option 2**: Skip specific hooks if needed (not recommended):
  ```bash
  git push --no-verify
  ```

### Parallel Execution Issues

Hooks run in parallel by default. If you encounter issues:

1. Check lefthook version: `lefthook version`
2. Update lefthook if needed
3. Run hooks sequentially by removing `parallel: true` from `.lefthook.yml`

## Adding New Hooks

To add a new hook:

1. Edit [.lefthook.yml](../.lefthook.yml)
2. Add hook configuration:

```yaml
pre-commit:
  commands:
    new-hook:
      run: <command>
      glob: "<file-pattern>"
```

3. Test the hook:
   ```bash
   lefthook run pre-commit new-hook
   ```

4. Update this documentation

## Best Practices

1. **Fix issues immediately**: Don't skip hooks. Fix issues as they're found.

2. **Run hooks manually before committing**: Especially for pre-push hooks:
   ```bash
   hooks-run
   ```

3. **Keep hooks fast**: Pre-commit hooks should be fast (< 5 seconds). Move slow checks to pre-push.

4. **Document hook behavior**: Update this file when adding or modifying hooks.

5. **Test hooks locally**: Always test hooks before pushing changes to configuration.

## Integration with CI/CD

Lefthook hooks run locally. For CI/CD:

1. **Run same checks in CI**: Use the same tools (tflint, yamllint, etc.) in CI pipelines
2. **Share configuration**: Use the same config files (`.tflint.hcl`, `.yamllint`) in CI
3. **Fail fast**: Catch issues locally before they reach CI

## Related Documentation

- [.lefthook.yml](../.lefthook.yml) - Hook configuration
- [TOOLS.md](TOOLS.md) - Tool documentation
- [WORKFLOWS.md](WORKFLOWS.md) - Workflow examples
- [agents.md](../agents.md) - AI agent quick reference

## Additional Resources

- [Lefthook Documentation](https://github.com/evilmartians/lefthook)
- [Git Hooks Guide](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)

