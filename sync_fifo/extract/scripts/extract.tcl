# configure RC extraction to use postRoute engine and apply maximum effort level for timing signoff
setExtractRCMode -engine postRoute
setExtractRCMode -effortLevel signoff

# run RC extraction
extractRC

# write out SPEF files
foreach corner [all_rc_corners] {
    puts "writing SPEF for corner $corner"
    rcOut -rc_corner $corner -spef ../out/${BLOCK_NAME}_${corner}.spef
}
