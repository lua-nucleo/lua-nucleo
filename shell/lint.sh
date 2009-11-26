#!/bin/bash

# TODO: Rewrite in (meta-)Lua
# TODO: Use it in luamarca/smoke.sh

if [ -z "$1" ]; then
  echo "Usage: $0 <lua-files>" >&2
  exit 1
fi

LUA=lua
LUAC=luac

LISTGLOBALS="${LUAC} -o /dev/null -l"

STANDARD_GLOBALS=`${LUA} -e 'for k in pairs(_G) do print(k) end'`

errors=""

for filename in $@; do
  echo "--> Checking file '${filename}'"

  bytecode_dump=`${LISTGLOBALS} ${filename}` || {
      echo "--> FAIL (bytecode dump)"
      errors="${errors}\n* ${filename}: failed to dump bytecode"
      continue
    }

  setglobals=`echo "${bytecode_dump}" | grep SETGLOBAL`
  if [ ! -z "${setglobals}" ]; then
    echo "${setglobals}" >&2
    echo "--> FAIL (setglobal)"
    errors="${errors}\n* ${filename}: changes _G"
    continue
  fi

  getglobals=`echo "${bytecode_dump}" | grep GETGLOBAL`
  if [ ! -z "${getglobals}" ]; then
    # TODO: Probably the limit is too restrictive.
    #       At least allow user to "declare" some globals.
    illegal_globals=`echo "${getglobals}" | grep -v -F "${GLOBALS_TO_CACHE}"`
    if [ ! -z "${illegal_globals}" ]; then
      echo "${illegal_globals}" >&2
      echo "--> FAIL (illegal_globals)"
      errors="${errors}\n* ${filename}: reads undeclared globals"
      continue
    fi

    # Allowing user to access "legal" globals only in the main chunk.
    # You have to cache globals to do a proper benchmark.
    # TODO: What about global variable access benchmarks?
    uncached_globals=`echo "${bytecode_dump}" | awk 'NR==1, /^function/ { next } { print }' | grep GETGLOBAL`
    if [ ! -z "${uncached_globals}" ]; then
      echo "${uncached_globals}" >&2
      echo "--> FAIL (uncached_globals)"
      errors="${errors}\n* ${filename}: globals not cached in main chunk"
      continue
    fi
  fi

  echo "--> OK"
done

if [ ! -z "${errors}" ]; then
  echo -e "\nLint failed (see details above):" >&2
  echo -e "${errors}" >&2
  exit 2
else
  echo -e "\nOK"
fi
