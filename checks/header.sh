#!/bin/bash
# pmb: cette règle vérifie la présence de l’entête approprié dans le fichier source.

pmb_check_header() {

    local source_file=${1}
    local interpreter_header=${PMB_INTERPRETER_HEADER:-'#!/bin/bash'}

    local first_line=$( head -1 "${source_file}" )
    echo "${first_line}" | grep -q -e "${interpreter_header}"
    if [ "${?}" -ne 0 ]; then
        echo "${source_file},1,Le fichier ne commence pas avec l’entête ${interpreter_header},${first_line}"
    fi
}
