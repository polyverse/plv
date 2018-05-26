#!/bin/sh

# Drop the 'scan.sh/' initial arg
shift
  
if [ "$1" = "" ]; then
        SCAN_PATHS="$PWD"
else
        SCAN_PATHS="$@"
fi

for SCAN_PATH in $SCAN_PATHS; do
	SCAN_PATH="$SCAN_PATH/"
        echo "Scanning $SCAN_PATH..."
        find "$SCAN_PATH" -name \* -print | while read line; do
                TARGET="$(echo $line | sed 's|'$SCAN_PATH'||g')"
                if [ "$SCAN_PATH" = "$TARGET" ]; then
                        continue
                fi

		HEAD="$(head -c 4 ${SCAN_PATH}${TARGET} 2>/dev/null)"

		if [ "$HEAD" != $'\x7f\x45\x4c\x46' ]; then
			continue
		fi

                DTSTAMP="$(stat --format "%y" "${SCAN_PATH}${TARGET}" | awk '{print $1 " " $2}' | sed -E 's/(:[0-9]+)\.[0-9]+/\1/g')"

                CHECKSUM="$(cksum "${SCAN_PATH}${TARGET}" | awk '{print $1}')"

                ELF_COMMENTS="$(readelf --string-dump=.comment ${SCAN_PATH}${TARGET} 2>/dev/null)"
                if [ $? -ne 0 ]; then
                        IS_PV="-not elf--"
                else
                        if [ "$(echo "$ELF_COMMENTS" | grep "\-PV\-")" = "" ]; then
                                IS_PV="-vanilla--"
                        else
                                IS_PV="scrambled"
                                SHA="$(echo "$ELF_COMMENTS" | awk -F'(' '{print $2}' | awk -F')' '{print $1}' | awk -F'-' '{print $3}' | xargs)" 
                                IS_PV="PV-$SHA"
                        fi      
                fi
                printf "[%s] %s %-11s %s  %s\n" "$IS_PV" "$STAT" "$CHECKSUM" "$DTSTAMP" "$line"
        done
done
