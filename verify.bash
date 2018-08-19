#! /bin/bash

set -e

EXPECTED_REMOTE_URL=${DRONE_REMOTE_URL}
EXPECTED_REMOTE_NAME='expected'
CSV_FILE='users.csv'
REMOTE_ORIGIN_MASTER_HEAD='1b15331985e1ee2463b7a055bc95be73c9179049'
ANSWER_BRANCH='answer'

function throw() {
  MESSAGE="$1"
  echo "$MESSAGE"
  false
}

function check-revision-by-file() {
  set -e
  FILE_PATH=$3
  # Prevent to pass removed files
  REVISION_1=`git rev-parse "$1:$FILE_PATH"` || throw '比較対象が存在しません'
  REVISION_2=`git rev-parse "$2:$FILE_PATH"` || throw '比較対象が存在しません'
  diff <(git show $REVISION_1) <(git show $REVISION_2) &> /dev/null || throw "$FILE_PATH が一致しません"
  echo OK
}

git fetch
ANSWER_BRANCH='master'
if git branch | grep --silent ${ANSWER_BRANCH}; then
    git checkout ${ANSWER_BRANCH}
    git reset --hard origin/${ANSWER_BRANCH}
else
    git checkout -b ${ANSWER_BRANCH} origin/${ANSWER_BRANCH}
fi

echo -n 'master の祖先に問題開始時点の origin/master が含まれている: '
git merge-base --is-ancestor "$REMOTE_ORIGIN_MASTER_HEAD" "heads/$ANSWER_BRANCH" || throw NG
echo OK

echo -n '正しい変更が反映されている: '
(git remote | grep "$EXPECTED_REMOTE_NAME" &> /dev/null) || git remote add "$EXPECTED_REMOTE_NAME" "$EXPECTED_REMOTE_URL"
git fetch "$EXPECTED_REMOTE_NAME" &> /dev/null
check-revision-by-file "$EXPECTED_REMOTE_NAME/$ANSWER_BRANCH" "heads/$ANSWER_BRANCH" "$CSV_FILE" || throw NG
