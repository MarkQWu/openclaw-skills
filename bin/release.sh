#!/bin/bash
# release.sh: 写入版本号到 VERSION、stage、打 tag，不自动 commit

VERSION="$1"
if [ -z "$VERSION" ] || ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "用法: bin/release.sh <版本号>  (semver 格式，如 1.9.0)"
  exit 1
fi

echo "$VERSION" > short-drama/VERSION
git add short-drama/VERSION
git tag "v${VERSION}"
echo "✅ VERSION 已写入 ${VERSION} 并 staged，tag v${VERSION} 已创建"
echo "   请在你的 release commit 中一起提交"
