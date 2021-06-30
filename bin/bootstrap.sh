#! /usr/bin/env bash
set -e +o pipefail

echo "Installing git configuration"
mkdir -p .git/hooks
pushd .git/hooks
for hook in ../../bin/git/hooks/* ; do
  rm -f $(basename $hook)
  ln -sf $hook
done
popd

echo "Disabling git case insensitive matches"
git config --local core.ignorecase false

echo "Bootstrapping complete!"
