#!/usr/bin/env fish

set os_name $argv[1]
set build_script build.sh
if test $os_name = "windows"
    set build_script build_mingw.sh
    set GITHUB_OUTPUT (cygpath "$GITHUB_OUTPUT")
end

function package_linux -a name
    tar -czf "$name.tar.gz" --exclude "bin/eo" bin/ doc/ include/ lib/ testing/ CREDITS.md LICENSE.md
end

function package_windows -a name
    zip -r "$name.zip" bin/ doc/ include/ lib/ testing/ CREDITS.md LICENSE.md -x "./bin/eo" "./bin/genie.exe"
end

function artifact -a branch
    hg checkout $branch

    set -l revision (hg identify --template '{id|short}')
    set -l date_string (date '+%Y-%m-%d')
    set artifact_name "scopes-unstable-$os_name-$date_string-$revision-$branch"

    echo "artifact-name-$branch=$artifact_name" >> $GITHUB_OUTPUT

    # patch genie recipe
    cp -f ../workarounds/genie.eo ./external/recipes/genie.eo

    rm -rf ./.eo/installed
    bash ./$build_script --silent-progress
    if test "$status" -ne 0
        exit 1
    end

    if test $os_name = "windows"
        package_windows $artifact_name
    else
        package_linux $artifact_name
    end
end

for branch in $argv[2..-1]
    artifact $branch
end
