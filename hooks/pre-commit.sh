#!/usr/bin/env bash
# Pre-commit hook - skanuje staged changes pod katem sekretow.
#
# Instalacja:
#   ln -s ../../hooks/pre-commit.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit
#
# Pomijanie dla konkretnej linii - dodaj komentarz na tej samej linii:
#   api_key = "xxx"  # pragma: allowlist secret
#
# Bypass calego hooka (NIE ROB tego w zwyklej pracy):
#   git commit --no-verify

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

FAIL=0

# Pobiera diff tylko dla staged zmian (nie dla juz committed)
DIFF=$(git diff --cached --unified=0 | grep -E '^\+' | grep -v '^+++')

if [ -z "$DIFF" ]; then
  exit 0
fi

check() {
  local pattern="$1"
  local description="$2"

  # Grep z -P (PCRE) dla zaawansowanych wzorcow; filtruj linie z 'pragma: allowlist secret'
  MATCHES=$(echo "$DIFF" | grep -P "$pattern" | grep -v 'pragma: allowlist secret' || true)

  if [ -n "$MATCHES" ]; then
    echo -e "${RED}[BLOCK]${NC} ${description}"
    echo "$MATCHES" | head -5 | sed 's/^/  /'
    FAIL=1
  fi
}

# Prywatne klucze
check '-----BEGIN (RSA |DSA |EC |OPENSSH )?PRIVATE KEY-----' 'Prywatny klucz kryptograficzny'

# Hasla plain
check "password\s*[:=]\s*['\"][^'\"]{6,}['\"]" 'Hardcoded password'
check "passwd\s*[:=]\s*['\"][^'\"]{6,}['\"]" 'Hardcoded passwd'
check "pwd\s*[:=]\s*['\"][^'\"]{6,}['\"]" 'Hardcoded pwd'

# Connection stringi
check 'postgres(ql)?://[^\s]*:[^\s]*@[^/\s]+' 'PostgreSQL connection string z hoslem'
check 'mysql://[^\s]*:[^\s]*@' 'MySQL connection string z hoslem'
check 'mongodb(\+srv)?://[^\s]*:[^\s]*@' 'MongoDB connection string z hoslem'
check 'redis://[^\s]*:[^\s]*@' 'Redis connection string z hoslem'

# Generic tokens / API keys
check "(api[_-]?key|apikey)\s*[:=]\s*['\"][A-Za-z0-9_\-]{20,}['\"]" 'API key'
check "(secret|token)\s*[:=]\s*['\"][A-Za-z0-9_\-]{20,}['\"]" 'Secret/token'

# GitHub
check 'ghp_[A-Za-z0-9]{36}' 'GitHub Personal Access Token (classic)'
check 'github_pat_[A-Za-z0-9_]{82}' 'GitHub PAT (fine-grained)'
check 'gho_[A-Za-z0-9]{36}' 'GitHub OAuth token'
check 'ghs_[A-Za-z0-9]{36}' 'GitHub App server token'

# AWS
check 'AKIA[0-9A-Z]{16}' 'AWS Access Key ID'
check 'aws_secret_access_key\s*[:=]\s*[A-Za-z0-9/+=]{40}' 'AWS Secret Access Key'

# GCP
check '"type":\s*"service_account"' 'GCP service account JSON'
check 'AIza[0-9A-Za-z_\-]{35}' 'Google API key'

# Stripe
check 'sk_live_[0-9a-zA-Z]{24,}' 'Stripe Live Secret Key'
check 'sk_test_[0-9a-zA-Z]{24,}' 'Stripe Test Secret Key'
check 'rk_live_[0-9a-zA-Z]{24,}' 'Stripe Restricted Key'

# OpenAI / Anthropic
check 'sk-[A-Za-z0-9]{32,}' 'OpenAI/Anthropic API key'
check 'sk-ant-[A-Za-z0-9_\-]{32,}' 'Anthropic API key'

# Slack
check 'xox[baprs]-[A-Za-z0-9-]{10,}' 'Slack token'
check 'https://hooks\.slack\.com/services/T[A-Z0-9]+/B[A-Z0-9]+/[A-Za-z0-9]+' 'Slack webhook'

# Supabase / JWT
check 'eyJ[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+' 'JWT token (byc moze Supabase service key)'

# SendGrid / Twilio / Mailgun
check 'SG\.[A-Za-z0-9_\-]{22}\.[A-Za-z0-9_\-]{43}' 'SendGrid API key'
check 'AC[a-z0-9]{32}' 'Twilio Account SID'
check 'key-[0-9a-zA-Z]{32}' 'Mailgun API key'

# Generic Bearer tokens
check "Bearer\s+[A-Za-z0-9_\-\.]{30,}" 'Bearer token'

# Pliki ktore nie powinny byc commitowane (po nazwie)
STAGED_FILES=$(git diff --cached --name-only)
for f in $STAGED_FILES; do
  case "$f" in
    .env|.env.local|.env.production|.env.prod|.env.staging|.env.development)
      echo -e "${RED}[BLOCK]${NC} Nie commituj pliku: $f (powinien byc w .gitignore)"
      FAIL=1
      ;;
    *.pem|*.key|*.keystore|*.jks|*.p12|*.pfx|id_rsa|id_rsa.pub|id_ed25519)
      echo -e "${RED}[BLOCK]${NC} Plik z kluczem/certyfikatem: $f"
      FAIL=1
      ;;
    *.sql|*.dump|*.sql.gz)
      # Backup bazy - warn, nie block (czasem commitujemy migracje .sql)
      # Sprawdz czy to nie backup (zawiera INSERT INTO z duzymi danymi)
      if git show ":$f" 2>/dev/null | head -50 | grep -q "^INSERT INTO.*VALUES"; then
        echo -e "${YELLOW}[WARN]${NC} $f wyglada jak backup z danymi - sprawdz czy to na pewno ma byc w repo"
      fi
      ;;
  esac
done

if [ $FAIL -eq 1 ]; then
  echo ""
  echo -e "${RED}Commit ZABLOKOWANY. Usun sekrety i sproboj ponownie.${NC}"
  echo ""
  echo "Jesli to false positive - dodaj komentarz '# pragma: allowlist secret' na linii."
  echo "Aby bypassnac hook (NIE ROB tego dla sekretow) - 'git commit --no-verify'."
  exit 1
fi

exit 0
