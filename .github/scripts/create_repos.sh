#!/bin/bash
generate_hashes() {
  HASH_TYPE="$1"
  HASH_COMMAND="$2"
  echo "${HASH_TYPE}:"
  find "main" -type f | while read -r file
  do
    echo " $(${HASH_COMMAND} "$file" | cut -d" " -f1) $(wc -c "$file")"
  done
}

main() {
  GOT_DEB=0
  DEB_POOL="_site/deb/pool/main"
  DEB_DISTS_COMPONENTS="dists/stable/main/binary-arm64"
  if release=$(curl -fqs https://api.github.com/repos/baluchicken/aptrepo/releases/latest)
  then
    tag="$(echo "$release" | jq -r '.tag_name')"
    deb_file="$(echo "$release" | jq -r '.assets[] | select(.name | endswith(".deb")) | .name')"
    echo "Parsing repo /baluchicken/aptrepo at $tag"
    if [ -n "$deb_file" ]
    then
      GOT_DEB=1
      mkdir -p "$DEB_POOL"
      pushd "$DEB_POOL" >/dev/null
      echo "Getting DEB"
      wget -q "https://github.com/baluchicken/aptrepo/releases/download/${tag}/${deb_file}"
      popd >/dev/null
    fi
  fi

  if [ $GOT_DEB -eq 1 ]
  then
    pushd _site/deb >/dev/null
    mkdir -p "${DEB_DISTS_COMPONENTS}"
    echo "Scanning all downloaded DEB Packages and creating Packages file."
    dpkg-scanpackages --arch arm64 pool/ > "${DEB_DISTS_COMPONENTS}/Packages"
    gzip -9 > "${DEB_DISTS_COMPONENTS}/Packages.gz" < "${DEB_DISTS_COMPONENTS}/Packages"
    bzip2 -9 > "${DEB_DISTS_COMPONENTS}/Packages.bz2" < "${DEB_DISTS_COMPONENTS}/Packages"
    popd >/dev/null
    pushd "_site/deb/dists/stable/" >/dev/null
    echo "Making Release file"
    {
      echo "Origin: ${ORIGIN}"
      echo "Label: ${REPO_OWNER}"
      echo "Suite: stable"
      echo "Codename: stable"
      echo "Version: 1.0"
      echo "Architectures: arm64"
      echo "Components: main"
      echo "Description: A repository for packages released by ${REPO_OWNER}}"
      echo "Date: $(date -Ru)"
      generate_hashes MD5Sum md5sum
      generate_hashes SHA1 sha1sum
      generate_hashes SHA256 sha256sum
    } > Release
    echo "Signing Release file"
    gpg --detach-sign --armor --sign > Release.gpg < Release
    gpg --detach-sign --armor --sign --clearsign > InRelease < Release
    echo "DEB repo built"
    popd >/dev/null
  fi
}
main