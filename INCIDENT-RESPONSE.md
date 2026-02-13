# Incident Response: Exposed API Token in backup-s3.sh

## Issue/Symptom

The file `backup-s3.sh` contained a hardcoded Cloudflare API token, which was committed to the repository. Even after removing the file with `git rm`, the sensitive information remained in the git history, posing a security risk. This could allow unauthorized access to Cloudflare resources if the token is compromised.

## Resolution Steps

1. **Identify affected commits**:  
   Run `git log --oneline --all -- backup-s3.sh` to list all commits that modified the file.

2. **Commit pending changes**:  
   Ensure the working directory is clean by staging and committing any unstaged changes:  
   `git add . && git commit -m "Commit pending changes before filtering"`

3. **Remove file from history**:  
   Use `git filter-branch` to rewrite history and remove the file from all commits:  
   `git filter-branch --tree-filter 'rm -f backup-s3.sh' --prune-empty -- --all`

4. **Clean up refs**:  
   Remove the backup refs created by filter-branch:  
   `git for-each-ref --format="delete %(refname)" refs/original | git update-ref --stdin`

5. **Verify removal**:  
   Confirm the file is no longer in history:  
   `git log --oneline --all -- backup-s3.sh` should return no output.

6. **Force push to remote**:  
   Overwrite the remote repository history:  
   `git push origin --force --all`  
   **Warning**: This will overwrite remote history. Coordinate with team members and ensure no one has unpushed work.

## Prevention Measures

- Avoid hardcoding secrets in code; use environment variables (e.g., `CLOUDFLARE_API_TOKEN`) or secret management tools.
- Add sensitive files to `.gitignore` immediately.
- Regularly audit repository history for exposed secrets using tools like `git-secrets` or manual checks.
- Implement pre-commit hooks to scan for secrets before commits.
- Rotate compromised credentials immediately.