sed -i -e 's|///\s*ditto$||g' -e 's|//\s*docmain$||g' -e  's|//\s*setter$||g' -e 's|//\s*getter$||g' -e 's|///\s*$||g' $@
#dfix $@
dfmt -i --brace_style=otbs --indent_size=3 $@
