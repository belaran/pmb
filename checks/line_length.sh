#!/bin/bash
# pmb: cette règle vérifie qu’aucune ligne du fichier ne dépasse pas la taille maximum autorisée.

pmb_check_line_length() {

    local source_file=${1}
    local nb_max_characters=${PMB_NB_MAX_CHARACTERS_BY_LINE:-120}

    nb_line=1
    cat "${source_file}" | \
    while
      read line
    do
      line_length=$(echo ${line} | wc -c)
      if [[ ${line_length} -gt ${nb_max_characters} ]]; then
        echo "${source_file},${nb_line},La ligne numéro ${nb_line} est plus longue que ${nb_max_characters},${line}"
      fi
      nb_line=$(expr "${nb_line}" + 1)
    done
}
