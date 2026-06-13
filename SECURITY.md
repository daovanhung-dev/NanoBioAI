# Security Guidelines - BioAI Project

## 🔒 Critical Security Rules

### ⚠️ NEVER Commit These Files:

1. **`.env` files** - Contains API keys and secrets
2. **`*.db` files** - Local SQLite database with user data
3. **`*_key.json`** - Service account credentials
4. **`*.jks` / `*.p12`** - Android/iOS signing keys
5. **`google-services.json`** - Firebase config (if used)

---

## ✅ Setup Instructions for New Team Members

### 1. Clone Repository

```bash
git clone <repository-url>
cd nano_app
```

### 2. Copy Environment Template

```bash
cp .env.example .env
```

### 3. Fill in Your API Keys

Edit `.env` and add your actual keys:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-actual-key
GEMINI_API_KEY=your-actual-key
```

### 4. Verify .env is in .gitignore

```bash
# Should show .env is ignored
git status

# .env should NOT appear in untracked files
```

---

## 🔐 How to Get API Keys

### Supabase
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to Settings > API
4. Copy `URL` and `anon/public` key

### Google Gemini
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create API key
3. Copy the key

---

## 🚨 If You Accidentally Commit Secrets

### Immediate Actions:

1. **Rotate the keys immediately**
   - Supabase: Project Settings > API > Reset keys
   - Gemini: Revoke and create new key

2. **Remove from Git history** (if just committed):
   ```bash
   # If not pushed yet
   git reset HEAD~1
   
   # If already pushed (use with caution!)
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch .env" \
     --prune-empty --tag-name-filter cat -- --all
   
   # Force push (DANGEROUS - coordinate with team!)
   git push origin --force --all
   ```

3. **Inform team** about key rotation

---

## 📋 Pre-Commit Checklist

Before every commit, verify:

- [ ] `.env` is NOT staged
- [ ] No `*.db` files staged
- [ ] No API keys in code comments
- [ ] No credentials in console.log/print statements
- [ ] No hardcoded passwords or tokens

### Use Git Pre-Commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/sh

# Check for .env file
if git diff --cached --name-only | grep -q "^\.env$"; then
    echo "ERROR: Attempting to commit .env file!"
    echo "Remove .env from commit: git reset HEAD .env"
    exit 1
fi

# Check for database files
if git diff --cached --name-only | grep -q "\.db$"; then
    echo "ERROR: Attempting to commit database file!"
    exit 1
fi

# Check for potential secrets in code
if git diff --cached -G"(api[_-]?key|secret|password|token)" | grep -i "api[_-]?key\|secret\|password\|token"; then
    echo "WARNING: Potential secret detected in staged changes"
    echo "Please review carefully before committing"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

exit 0
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

---

## 🗄️ Database Security

### Local SQLite Database

- **Never commit** `bioai.db` to git
- Database contains user health data (sensitive!)
- Use `.db` in `.gitignore`

### For Testing:

```dart
// Use mock data instead of real user data
final testUser = UserEntity(
  id: 'test-id',
  email: 'test@example.com',
  // ... mock data
);
```

---

## 🔍 Security Audit Commands

### Check for exposed secrets in history:

```bash
# Search for potential secrets
git log -S "api_key" --all
git log -S "secret" --all
git log -S "password" --all

# Check current staged changes
git diff --cached | grep -i "api_key\|secret\|password"
```

### Scan with tools:

```bash
# Install gitleaks
brew install gitleaks

# Scan repository
gitleaks detect --source . --verbose

# Scan specific commit
gitleaks detect --source . --log-opts="--since='2024-01-01'"
```

---

## 📝 Environment Variables in CI/CD

### GitHub Actions

Add secrets in: Repository Settings > Secrets and variables > Actions

```yaml
# .github/workflows/deploy.yml
env:
  SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
  SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
  GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
```

### GitLab CI

Add in: Settings > CI/CD > Variables

```yaml
# .gitlab-ci.yml
variables:
  SUPABASE_URL: $SUPABASE_URL
  SUPABASE_ANON_KEY: $SUPABASE_ANON_KEY
  GEMINI_API_KEY: $GEMINI_API_KEY
```

---

## ⚡ Quick Security Checks

```bash
# 1. Check .env is ignored
git check-ignore .env
# Should output: .env

# 2. Check no secrets in staged files
git diff --cached | grep -E "(api|key|secret|password|token)" -i

# 3. Verify gitignore is working
git status --ignored

# 4. List all tracked files (should not see .env)
git ls-files | grep "\.env"
# Should output nothing
```

---

## 🆘 Emergency Contacts

If you discover a security vulnerability:

1. **DO NOT** create a public issue
2. Email: [security@yourcompany.com]
3. Use responsible disclosure
4. Provide details: what, where, how to reproduce

---

## 📚 Additional Resources

- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [Flutter Security Best Practices](https://docs.flutter.dev/security)
- [Git Secret Management](https://git-secret.io/)

---

**Remember: Security is everyone's responsibility!** 🔐
