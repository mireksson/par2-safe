@echo off
pushd ..

rem ===== main =====
git init --initial-branch=main
git add *.md
git add LICENSE
git commit -m "Repository created"

rem ===== dev =====
rem git checkout -b dev

rem ===== feature/dev-in-progress (active work) =====
git checkout -b feature/dev-in-progress

git add .gitignore
git add -f .meta/*
git commit -m "Repository mechanics"

git add .
git commit -m "Initial codebase"

rem ===== archive/initial-codebase (snapshot of feature) =====
git checkout -b archive/initial-codebase

rem ===== return to feature (working default) =====
git checkout feature/dev-in-progress

popd
