#!/bin/bash
set -e
usage() {
  echo 'TODO'
}

# Sanity check - let's unsure that CHECKS_HOME have been defined properly
readonly CHECKS_HOME=${CHECKS_HOME:-"$(pwd)/checks/"}

if [ ! -d "${CHECKS_HOME}" ] ; then
   echo "La valeur de CHECKS_HOME n’indique pas l’emplacement d’un répertoire"
   usage
   exit 1
fi

readonly SOURCES_ROOT_DIR=${1}
shift

if [ -z "${SOURCES_ROOT_DIR}" ]; then
  echo "Le répertoire raçine des fichiers sources n'a pas été définie."
  usage
  exit 2
fi

if [ ! -d "${SOURCES_ROOT_DIR}" ]; then
  echo "${SOURCES_ROOT_DIR} n'est pas un répertoire."
  usage
  exit 3
fi

while getopts "hr:" opt
do
	case ${opt} in
        h)
           usage
           ;;
		r)
           readonly REPORT_FILE="${OPTARG}"
           if [ ! -w "${REPORT_FILE}" ]; then
               echo "Impossible d'écrire le rapport dans le fichier ${REPORT_FILE}."
               usage
               exit 4
           fi
           ;;
		*)
           echo "$(basename ${0}) ne reconnait pas cette option: ${OPT}."
           usage
           exit 5
           ;;
	esac
done

debug_msg() {

  local mssg=${1}
  if [ ! -z "${DEBUG}" ]; then
    echo "${mssg}"
  fi
}

# loading rules
for check in "${CHECKS_HOME}"/*
do
    debug_msg "Loading check: ${check}"
    source "${check}"
done

readonly CSV_REPORT=$(mktemp)
for check in $(ls -1 "${CHECKS_HOME}"/*)
do
    for source_file in ${SOURCES_ROOT_DIR}/*
    do
      debug_msg "Checking file: ${source_file}."
      pmb_check_$(basename --suffix .sh "${check}") "${source_file}" >> ${CSV_REPORT}
    done
done

# generation of (x)html report
xhtml_header() {
  echo '<html>'
  echo '<title>PMB Report</title>'
  echo '<body>'
}

xhtml_footer() {
  echo '</body>'
  echo '</html>'
}

xhtml_infraction_table() {
  local filename=$(basename ${1})
  local csv_report=${2}

  echo '<table>'
  echo '<th>Numéro de ligne</th><th>Message</th><th>Extrait de code</th>'
  grep -e "${filename}" "${csv_report}" | cut -d, -f2- | \
      sed -e 's;^\([0-9]*\),\([^,]*\),\(.*\)$;<tr><td>\1</td><td>\2</td><td>\3</td></tr>;'
  echo '</table>'
}

xhtml_file() {
  local source_file=${1}
  local csv_report=${2}

  echo "<li>${source_file}:"
  xhtml_infraction_table "${source_file}" "${csv_report}"
  echo '</li>'
}

generate_xhtml_report() {
  local csv_report=${1}

  xhtml_header
  echo '<ul>'
  cut -f1 -d, "${CSV_REPORT}" | sort -u  | \
  while
    read source_file
  do
    xhtml_file "${source_file}" "${csv_report}"
  done
  echo '</ul>'
  xhtml_footer
}

if [ ! -z "${REPORT_FILE}" ]; then
  generate_xhtml_report "${CSV_REPORT}" >> "${REPORT_FILE}"
  which 'xmlwf' > /dev/null
  if [ "${?}" -eq 0 ]; then
    xmlwf "${REPORT_FILE}"
  fi
else
  generate_xhtml_report "${CSV_REPORT}"
fi
rm -f "${CSV_REPORT}"
