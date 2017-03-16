#!/usr/bin/env bash

set -eu

if [ -f "${VSI_COMMON_DIR-}/linux/just_functions.bsh" ]; then
  source "${VSI_COMMON_DIR}/linux/just_functions.bsh"
fi

CURDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)

: ${DRYRUN=} #export DRYRUN=echo for "dryrun"

IMAGE_NAME=andyneff/vscode

function Docker()
{
  $DRYRUN docker "${@}"
}

function caseify()
{
  local just_arg=$1
  shift 1

  case ${just_arg} in
    build)
      Docker build -t "${IMAGE_NAME}" "${CURDIR}"
      ;;
    push)
      Docker push "${IMAGE_NAME}"
      ;;
    run)
      Docker run -it --rm -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY \
                 -e USER_ID=`id -u` -e GROUP_ID=`id -g` ${@+"${@}"} "${IMAGE_NAME}"
      extra_args+=$#
      ;;
    *)
      defaultify "${just_arg}" ${@+"${@}"}
      ;;
  esac
}

if ! command -v justify &> /dev/null; then function justify(){ caseify ${@+"${@}"};};fi

justify ${@+"${@}"}
