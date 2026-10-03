#!/usr/bin/env bash
# Installs the NER model where the app looks for it: <app support>/models.
# On macOS the app is sandboxed, so that is inside its container:
# ~/Library/Containers/com.stonetech.docudis/Data/Library/Application Support/com.stonetech.docudis/models.
# Each model.json and its binaries come from the docudis-ner revision pinned
# in tool/native.lock.json and are checked against its manifest's SHA-256.
#
#   tool/fetch_models.sh                  # the shipped model, xlmr_ner_docudis
#   tool/fetch_models.sh --dest DIR       # somewhere else
#
# Files already in place with the right SHA-256 are kept, so copying a model
# downloaded elsewhere into the destination first skips the download.
# Downloading needs `pip install huggingface_hub`; the model repositories are
# public. PYTHON selects the interpreter (default python3).
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
lock="$repo_root/tool/native.lock.json"
field() { python3 -c "import json; print(json.load(open('$lock'))$1)"; }
repository="$(field "['docudis_ner']['repository']")"
revision="$(field "['docudis_ner']['revision']")"

dest=""
args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dest) dest="$2"; shift 2 ;;
    *) args+=("$1"); shift ;;
  esac
done
if [[ -z "$dest" ]]; then
  case "$(uname -s)" in
    Darwin) dest="$HOME/Library/Containers/com.stonetech.docudis/Data/Library/Application Support/com.stonetech.docudis/models" ;;
    *) echo "pass --dest on this platform" >&2; exit 2 ;;
  esac
  # Let macOS create the container itself rather than making it here.
  if [[ ! -f "$HOME/Library/Containers/com.stonetech.docudis/.com.apple.containermanagerd.metadata.plist" ]]; then
    echo "open Docudis once (flutter run -d macos) so macOS creates its container, then run this again" >&2
    exit 1
  fi
fi

source_dir="$repo_root/build/native-cache/src/docudis-ner-$revision"
if [[ ! -d "$source_dir/.git" ]]; then
  mkdir -p "$source_dir"
  git -C "$source_dir" init -q
  git -C "$source_dir" remote add origin "$repository"
fi
if [[ "$(git -C "$source_dir" rev-parse -q --verify HEAD || true)" != "$revision" ]]; then
  git -C "$source_dir" fetch -q --depth 1 origin "$revision"
  git -C "$source_dir" checkout -q --detach FETCH_HEAD
fi

"${PYTHON:-python3}" "$source_dir/tool/fetch_models.py" --dest "$dest" ${args[@]+"${args[@]}"}
