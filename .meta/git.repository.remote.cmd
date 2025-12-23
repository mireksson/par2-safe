@echo off
pushd "%~dp0\.."

set account=mireksson
for %%I in ("%CD%") do set "project=%%~nxI"
set git=https://github.com/%account%/%project%.git

git ls-remote "%git%" >nul 2>&1 || (
  echo Remote repo does not exist: %git%
  exit /b 1
)

git remote remove origin 2>nul
git remote add origin "%git%"
git push --all origin

rem local mirror force
rem git push "%git%" --mirror --force

popd