#!/usr/bin/env bash

if [[ $# -lt 2 ]]; then
    echo "Usage: upgrade-terraform <file-containing-space-separated-paths> <desired-version>"
    exit 1
fi

NEW_TERRAFORM_VERSION=$2
PATTERN="0\.12\.2[0-9]"
if [[ ! "${NEW_TERRAFORM_VERSION}" =~ $PATTERN ]]; then
  echo "Unexpected new version format ${NEW_TERRAFORM_VERSION}, expected to match ${PATTERN}"
  exit 1;
fi

NEWLINE=$'\n'
COMMIT_HEADER="Update Terraform to ${2}"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
echo "Starting in ${DIR}${NEWLINE}----------------------------------------------"
echo "${COMMIT_MESSAGE}${NEWLINE}----------------------------------------------"

INPUT_FILE="${DIR}/$1"
if [ ! -f "${INPUT_FILE}" ]; then
  echo "Unable to find input file ${INPUT_FILE}. Exiting."
  exit 1
fi

IFS=' '
FILE_AS_STR="$(sed ':a;N;$!ba;s/\n/ /g' ${INPUT_FILE})"
echo "Projects to update: ${FILE_AS_STR}"

read -a _PATHS <<< "${FILE_AS_STR}" || exit 1

for i in "${_PATHS[@]}"
do
   TRAVIS_YML="${DIR}/../${i}/.travis.yml"
   echo "--------------------------------------------------------------------------------------------${NEWLINE}Starting ${i}:${TRAVIS_YML}${NEWLINE}"

   cd "${DIR}" || exit 1
   echo "Editing ${DIR}/../${i}/.travis.yml Terraform to ${2}"
   cd "${DIR}/../${i}" || exit 1
   BRANCH=$(git rev-parse --abbrev-ref HEAD)

   if [[ "${BRANCH}" != "master" ]]; then
      echo "${i} is not a master branch. It is on '${BRANCH}'. Exiting."
      exit 1
   fi

   # Make sure the branch tracks master
   git branch --set-upstream-to=origin/master master || exit 1

   # Get latest changes from master
   git pull origin master --rebase || exit 1

   STATUS=$(git status | grep ^"Your branch is ahead of 'origin/master' by")
   if [[ -n "${STATUS}" ]]; then
      echo "${i} ${STATUS}. Exiting."
      exit 1
   fi

   CHANGES=$(git status --porcelain | grep ^"$AM ")
   if [[ -n "${CHANGES}" ]]; then
      echo "${i} contains changes. Exiting."
      exit 1
   fi

   echo "Updating ${TRAVIS_YML} Terraform to ${2}"
   sed -i -E "s/  - VERSION=0.12.2[0-9]/  - VERSION=${2}/g" "${TRAVIS_YML}"
   git add "${TRAVIS_YML}" || exit 1

   COMMIT_RESULT="$(git commit -m '${COMMIT_MESSAGE}' | grep "nothing to commit")"
   if [[ ! -n "${COMMIT_RESULT}" ]]; then
      echo "${i} commit succeeded. pushing."
      git push origin master
   else
      echo "${i} ${COMMIT_RESULT}. Nothing to push."
   fi

   echo "Finished ${TRAVIS_YML}${NEWLINE}--------------------------------------------------------------------------------------------"
done

