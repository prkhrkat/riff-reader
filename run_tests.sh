#!/bin/bash
set -e

echo "🧪 Running Riff Reader Test Suite..."
echo "===================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Run unit tests
echo ""
echo "📝 Running Unit Tests..."
xcodebuild test \
    -scheme RiffReader \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    -only-testing:RiffReaderTests \
    2>&1 | grep -E "(Test Suite|Test Case|Failing|Passing|passed|failed|error:)" || true

# Check if tests passed
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo ""
    exit 0
else
    echo ""
    echo -e "${RED}❌ Tests failed!${NC}"
    echo -e "${YELLOW}Fix the issues before committing.${NC}"
    echo ""
    exit 1
fi
