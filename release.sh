#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${GREEN}==>${NC} $1"
}

print_error() {
    echo -e "${RED}Error:${NC} $1"
    exit 1
}

print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

# Parse arguments
WAIT_ONLY=false
if [ "$1" == "--wait-only" ]; then
    WAIT_ONLY=true
    shift
fi

# Check if version argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 [--wait-only] <version>"
    echo "Example: $0 0.1.3"
    echo "         $0 --wait-only 0.1.3  # Skip to waiting for artifacts"
    exit 1
fi

NEW_VERSION=$1

# Validate version format
if ! [[ $NEW_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_error "Invalid version format. Use semantic versioning (e.g., 0.1.3)"
fi

# Skip initial steps if --wait-only flag is set
if [ "$WAIT_ONLY" = false ]; then
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        print_error "You have uncommitted changes. Please commit or stash them first."
    fi

    # Check we're on main branch
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    if [ "$CURRENT_BRANCH" != "main" ]; then
        print_warning "You're not on main branch (current: $CURRENT_BRANCH)"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    print_step "Updating version in mix.exs to $NEW_VERSION"

    # Update version in mix.exs
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/@version \".*\"/@version \"$NEW_VERSION\"/" mix.exs
    else
        # Linux
        sed -i "s/@version \".*\"/@version \"$NEW_VERSION\"/" mix.exs
    fi

    print_step "Committing version change"
    git add mix.exs
    git commit -m "Bump version to $NEW_VERSION"

    print_step "Creating and pushing tag v$NEW_VERSION"
    git tag "v$NEW_VERSION"
    git push origin main
    git push origin "v$NEW_VERSION"
fi

print_step "Waiting for GitHub Actions to build releases..."
echo "You can monitor the build at: https://github.com/Valian/extractous_ex/actions"
echo ""
echo "Polling for release artifacts..."

# Function to check if all artifacts are available
check_artifacts_ready() {
    local version=$1
    local base_url="https://github.com/Valian/extractous_ex/releases/download/v${version}"

    # List of expected artifacts (based on your targets)
    local artifacts=(
        "libextractousex_native-v${version}-nif-2.15-aarch64-apple-darwin.so.tar.gz"
        "libextractousex_native-v${version}-nif-2.15-x86_64-apple-darwin.so.tar.gz"
        "libextractousex_native-v${version}-nif-2.15-x86_64-unknown-linux-gnu.so.tar.gz"
        "libextractousex_native-v${version}-nif-2.15-x86_64-pc-windows-gnu.dll.tar.gz"
    )

    for artifact in "${artifacts[@]}"; do
        if ! curl -s -f -I "${base_url}/${artifact}" > /dev/null 2>&1; then
            return 1
        fi
    done

    return 0
}

# Poll for up to 30 minutes
MAX_WAIT=1800  # 30 minutes in seconds
POLL_INTERVAL=30  # Check every 30 seconds
elapsed=0

while [ $elapsed -lt $MAX_WAIT ]; do
    if check_artifacts_ready "$NEW_VERSION"; then
        print_step "All artifacts are ready!"
        break
    fi

    echo -n "."
    sleep $POLL_INTERVAL
    elapsed=$((elapsed + POLL_INTERVAL))
done

if [ $elapsed -ge $MAX_WAIT ]; then
    print_error "Timeout waiting for artifacts. Please check GitHub Actions manually."
fi

print_step "Downloading checksums for all precompiled artifacts"

# Generate checksums
EXTRACTOUS_EX_BUILD=1 mix rustler_precompiled.download ExtractousEx.Native --all --ignore-unavailable --print > "checksum-Elixir.ExtractousEx.Native.exs"

print_step "Checksum file generated successfully"


print_step "Publishing to Hex"
echo ""
echo "Ready to publish to Hex.pm!"
echo ""
read -p "Do you want to publish now? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    mix hex.publish
    print_step "Successfully published version $NEW_VERSION! 🎉"
else
    echo ""
    echo "Skipped publishing. When you're ready, run:"
    echo "  mix hex.publish"
fi

echo ""
echo "Release process complete for v$NEW_VERSION"