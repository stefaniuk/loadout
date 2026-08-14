#!/bin/bash

cd "$(git rev-parse --show-toplevel)" || exit 1
cd .github/skills/repository-template || exit 1
rm -rf assets
git clone https://github.com/stefaniuk/repository-template.git assets
cd assets || exit 1
git pull origin v2
git checkout v2
