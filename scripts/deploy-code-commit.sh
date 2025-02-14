#!/usr/bin/env bash
##
# Deploy code commit.
#
# Push code repository releases to another repository.
#
# Optionally, select which subdirectory in the source repository is copied to
# which location in the destination repository.
#
# Optionally, provide a custom .gitignore.release file with included and
# excluded source files. Useful for including artifacts produced by CI that
# are not committed in the source repository.
#
# shellcheck disable=SC2086

set -e
[ -n "${DREVOPS_DEBUG}" ] && set -x

CURDIR="$(cd "$(dirname "$1")"; pwd -P)/$(basename "$1")"

# Remote repository URL.
DEPLOY_CODE_COMMIT_REMOTE_REPO="${DEPLOY_CODE_COMMIT_REMOTE_REPO:-}"

# Remote repository branch to push commits to.
DEPLOY_CODE_COMMIT_REMOTE_BRANCH="${DEPLOY_CODE_COMMIT_REMOTE_BRANCH:-}"

# Absolute path to the directory to copy files from.
# Defaults to the current directory.
DEPLOY_CODE_COMMIT_SRC_DIR="${DEPLOY_CODE_COMMIT_SRC_DIR:-${CURDIR}}"

# Relative path to the directory within the destination repository.
# Defaults to the root of the destination repository.
DEPLOY_CODE_COMMIT_DST_DIR="${DEPLOY_CODE_COMMIT_DST_DIR:-./}"

# Custom .gitignore location to replace .gitignore in the DEPLOY_CODE_COMMIT_SRC_DIR
# in order to selectively include and exclude directories that are going into
# the release.
# If does not exist - the current .gitignore will be left unchanged.
DEPLOY_CODE_COMMIT_GITIGNORE="${DEPLOY_CODE_COMMIT_GITIGNORE:-${DEPLOY_CODE_COMMIT_SRC_DIR}/.gitignore.release}"

# Email address of the user who will be committing to a remote repository.
DEPLOY_GIT_USER_NAME="${DEPLOY_GIT_USER_NAME:-"Deployer Robot"}"

# Name of the user who will be committing to a remote repository.
DEPLOY_GIT_USER_EMAIL="${DEPLOY_GIT_USER_EMAIL:-}"

# SSH key fingerprint used to connect to a remote. If not used, the currently
# loaded default SSH key (the key used for code checkout) will be used or
# deployment will fail with an error if the default SSH key is not loaded.
# In most cases, the default SSH key does not work (because it is a read-only
# key used by CircleCI to checkout code from git), so you should add another
# deployment key.
DEPLOY_SSH_FINGERPRINT="${DEPLOY_SSH_FINGERPRINT:-}"

# Default SSH file used if custom fingerprint is not provided.
DEPLOY_SSH_FILE="${DEPLOY_SSH_FILE:-${HOME}/.ssh/id_rsa}"

# Proceed with push.
DEPLOY_CODE_COMMIT_PUSH_PROCEED="${DEPLOY_CODE_COMMIT_PUSH_PROCEED:-0}"

################################################################################

echo "==> Started code release."

# Check all required values.
[ -z "${DEPLOY_CODE_COMMIT_REMOTE_REPO}" ] && echo "Missing required value for DEPLOY_CODE_COMMIT_REMOTE_REPO." && exit 1
[ -z "${DEPLOY_CODE_COMMIT_REMOTE_BRANCH}" ] && echo "Missing required value for DEPLOY_CODE_COMMIT_REMOTE_BRANCH." && exit 1
[ -z "${DEPLOY_CODE_COMMIT_SRC_DIR}" ] && echo "Missing required value for DEPLOY_CODE_COMMIT_SRC_DIR." && exit 1
[ -z "${DEPLOY_CODE_COMMIT_DST_DIR}" ] && echo "Missing required value for DEPLOY_CODE_COMMIT_DST_DIR." && exit 1
[ -z "${DEPLOY_CODE_COMMIT_GITIGNORE}" ] && echo "Missing required value for DEPLOY_CODE_COMMIT_GITIGNORE." && exit 1
[ -z "${DEPLOY_GIT_USER_NAME}" ] && echo "Missing required value for DEPLOY_GIT_USER_NAME." && exit 1
[ -z "${DEPLOY_GIT_USER_EMAIL}" ] && echo "Missing required value for DEPLOY_GIT_USER_EMAIL." && exit 1

[ ! -d "${DEPLOY_CODE_COMMIT_SRC_DIR}" ] && echo "ERROR: Unable to find source directory ${DEPLOY_CODE_COMMIT_SRC_DIR}." && exit 1

##
## Git and SSH key setup.
##

# Configure global git settings, if they do not exist.
[ "$(git config --global user.name)" == "" ] && echo "==> Configuring global git user name." && git config --global user.name "${DEPLOY_GIT_USER_NAME}"
[ "$(git config --global user.email)" == "" ] && echo "==> Configuring global git user email." && git config --global user.email "${DEPLOY_GIT_USER_EMAIL}"

# Use custom deploy key if the fingerprint was provided.
if [ -n "${DEPLOY_SSH_FINGERPRINT}" ]; then
  echo "==> Custom deployment key is provided."
  DEPLOY_SSH_FILE="${DEPLOY_SSH_FINGERPRINT//:}"
  DEPLOY_SSH_FILE="${HOME}/.ssh/id_rsa_${DEPLOY_SSH_FILE//\"}"
fi

[ ! -f "${DEPLOY_SSH_FILE}" ] && echo "ERROR: SSH key file ${DEPLOY_SSH_FILE} does not exist." && exit 1

# Check if the key is loaded or load the key.
if ssh-add -l | grep -q "${DEPLOY_SSH_FILE}"; then
  echo "==> SSH agent has ${DEPLOY_SSH_FILE} key loaded."
else
  echo "==> SSH agent does not have default key loaded. Trying to load."
  # Remove all other keys and add SSH key from provided fingerprint into SSH agent.
  ssh-add -D > /dev/null
  ssh-add "${DEPLOY_SSH_FILE}"
fi

# Disable strict host key checking in CI.
[ -n "${CI}" ] && mkdir -p "${HOME}/.ssh/" && echo -e "\nHost *\n\tStrictHostKeyChecking no\n\tUserKnownHostsFile /dev/null\n" >> "${HOME}/.ssh/config"

##
## Code release.
##

#
# Remove content between #;< and #;> comments.
#
remove_special_comments_with_content() {
  local token="${1}"
  local dir="${2}"
  local sed_opts

  sed_opts=(-i) && [ "$(uname)" == "Darwin" ] && sed_opts=(-i '')
  grep -rI \
    --exclude-dir=".git" \
    --exclude-dir=".idea" \
    --exclude-dir="vendor" \
    --exclude-dir="node_modules" \
    -l "#;> $token" "${dir}" \
    | LC_ALL=C.UTF-8 xargs sed "${sed_opts[@]}" -e "/#;< $token/,/#;> $token/d" || true
}

#
# Replace string content.
#
replace_string_content() {
  local needle="${1}"
  local replacement="${2}"
  local dir="${3}"
  local sed_opts

  sed_opts=(-i) && [ "$(uname)" == "Darwin" ] && sed_opts=(-i '')
  grep -rI \
    --exclude-dir=".git" \
    --exclude-dir=".idea" \
    --exclude-dir="vendor" \
    --exclude-dir="node_modules" \
    -l "${needle}" "${dir}" \
    | xargs sed "${sed_opts[@]}" "s@$needle@$replacement@g" || true
}

# Create a temp directory to copy source repository into to prevent changes to source.
SRC_TMPDIR=$(mktemp -d)

echo "==> Copying files from the source repository to ${SRC_TMPDIR}."
rsync -a --keep-dirlinks ./. "${SRC_TMPDIR}"
[ -n "${DREVOPS_DEBUG}" ] && tree -L 4 "${SRC_TMPDIR}"

# Move to the temp source repo directory.
pushd "${SRC_TMPDIR}" >/dev/null || exit 1

# Reset any changes that may have been introduced during the CI run.
git reset --hard

latest_commit="$(git rev-parse HEAD)"
latest_commit_msg="$(git log -1 --pretty=%B)"
latest_commit_author="$(git show -s --format='%an <%ae>' HEAD)"

echo "  > Latest commit:         ${latest_commit}."
echo "  > Latest commit message: ${latest_commit_msg}."
echo "  > Latest commit author:  ${latest_commit_author}."

popd >/dev/null || exit 1

# Create a temp directory to checkout destination repository into.
DST_TMPDIR=$(mktemp -d)

# Move to the temp destination repo directory.
pushd "${DST_TMPDIR}" >/dev/null || exit 1

echo "==> Initialising an empty repository in ${DST_TMPDIR}."
git init -q

echo "==> Checking out remote branch ${DEPLOY_CODE_COMMIT_REMOTE_BRANCH}."
git remote add destination "${DEPLOY_CODE_COMMIT_REMOTE_REPO}"
git fetch --all
git checkout -b "${DEPLOY_CODE_COMMIT_REMOTE_BRANCH}" "destination/${DEPLOY_CODE_COMMIT_REMOTE_BRANCH}"

# Clear files before adding new files to make sure that only the contents of
# the source repository at the latest version is present.
echo "==> Clearing files in ${DEPLOY_CODE_COMMIT_DST_DIR}."
git ls-tree -d --name-only --full-name -r HEAD "${DEPLOY_CODE_COMMIT_DST_DIR}/" | xargs rm -Rf
git ls-tree --full-tree --name-only -r HEAD "${DEPLOY_CODE_COMMIT_DST_DIR}/" | xargs rm -Rf

echo "==> Copying files from ${DEPLOY_CODE_COMMIT_SRC_DIR} to ${DEPLOY_CODE_COMMIT_DST_DIR}."
[ -n "${DREVOPS_DEBUG}" ] && tree -L 4 "${DEPLOY_CODE_COMMIT_SRC_DIR}"
# Copy all files, but preserve .git directory.
mv ".git" ".git.bak"
rsync -a --keep-dirlinks "${DEPLOY_CODE_COMMIT_SRC_DIR}/." "${DEPLOY_CODE_COMMIT_DST_DIR}"
rm -Rf .git
mv ".git.bak" ".git"

echo "==> Removing development code in ${DEPLOY_CODE_COMMIT_DST_DIR}."
remove_special_comments_with_content "DEVELOPMENT" "${DEPLOY_CODE_COMMIT_DST_DIR}"

# Allow to provide custom .gitignore.
if [ -f "${DEPLOY_CODE_COMMIT_GITIGNORE}" ]; then
  echo "==> Copying release .gitignore file ${DEPLOY_CODE_COMMIT_GITIGNORE} to ${DEPLOY_CODE_COMMIT_DST_DIR}/.gitignore"
  cp -Rf "${DEPLOY_CODE_COMMIT_GITIGNORE}" "${DEPLOY_CODE_COMMIT_DST_DIR}/.gitignore"
fi

echo -n "==> Checking for changes... "
status="$(git status)"
if [ -z "${status##*nothing to commit*}" ]; then
  echo "no changes were found. Nothing will be updated."
else
  echo "==> Committing new changes."
  git add -A
  git commit -m "${latest_commit_msg}" --author="${latest_commit_author}"

  echo "==> Pushing to remote."
  if [ "${DEPLOY_CODE_COMMIT_PUSH_PROCEED}" = "1" ]; then
    git push destination "${DEPLOY_CODE_COMMIT_REMOTE_BRANCH}"
  else
    echo "Would push to remote, but DEPLOY_CODE_COMMIT_PUSH_PROCEED is not set to 1."
  fi
fi

popd >/dev/null || exit 1

echo "==> Finished code release."
