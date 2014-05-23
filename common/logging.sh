#
#   Author: Rohith
#   Date: 2014-05-22 23:56:04 +0100 (Thu, 22 May 2014)
#
#  vim:ts=4:sw=4:et
#

annonce() {
  [ -n "$@" ] && echo "$@"
}

error() {
  echo "[ERROR]: $@"
  exit 1
}
