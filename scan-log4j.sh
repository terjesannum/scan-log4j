#!/usr/bin/env bash

TMPDIR=/tmp/scan-log4j
SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")

# ignore 2.17.0, 2.16.0
MD5='^(3dc5cf97546007be53b2f3d44028fa58|ba1cf8f81e7b31c709768561ba8ab558)$'

check_class() {
    md5sum $1 | cut -f1 -d\  | grep -qE $MD5
}

scan_files() {
    for file in $(find . -not \( -path ./proc -prune \) -type f -name \*.jar -o -name \*.zip -o -name JndiManager.class); do
        case $file in
            *.class)
                check_class $file || echo $file
                ;;
            *)
                rm -rf $TMPDIR
                mkdir $TMPDIR
                if type unzip &>/dev/null; then
                    unzip -d $TMPDIR $file \*JndiManager.class &>/dev/null
                else
                    python $SCRIPT_PATH/unzip.py $file $TMPDIR
                fi
                for class in $(find $TMPDIR -name \*.class); do
                    if ! check_class $class; then
                        echo $file
                        break
                    fi
                done
                rm -r $TMPDIR
                ;;
            
        esac
    done
}

for id in $(docker ps --format "{{.ID}}"); do
    pid=$(docker inspect $id -f '{{.State.Pid}}')
    namespace=$(docker inspect $id -f '{{ index .Config.Labels "io.kubernetes.pod.namespace"}}')
    pod=$(docker inspect $id -f '{{ index .Config.Labels "io.kubernetes.pod.name"}}')
    container=$(docker inspect $id -f '{{ index .Config.Labels "io.kubernetes.container.name"}}')
    found=`(cd /proc/$pid/root; scan_files)`
    if test -n "$found"; then
        echo $container $pod $namespace $(hostname -f)
        echo "$found" | sed 's/^/  /'
    fi
done
