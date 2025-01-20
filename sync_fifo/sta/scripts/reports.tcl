foreach view [all_analysis_views] { 
    puts "reporting view $view"

    ##########################
    #Generate SI glitch report
    ##########################
    report_noise -view $view -txtfile ${REPORT_DIR}/glitch_${view}.rpt

    #####################
    # Reports that check design health
    #####################
    check_design -type timing -out_file    ${REPORT_DIR}/check_design_${view}.rpt
    check_timing -view $view -verbose > ${REPORT_DIR}/check_timing_${view}.rpt
    report_annotated_parasitics -view $view > ${REPORT_DIR}/annotated_${view}.rpt
    report_analysis_coverage -view $view > ${REPORT_DIR}/coverage_${view}.rpt

    #####################
    # Reports that describe constraints
    #####################
    report_clocks -view $view                      > ${REPORT_DIR}/clocks_${view}.rpt
    report_case_analysis -view $view               > ${REPORT_DIR}/case_analysis_${view}.rpt
    report_inactive_arcs -view $view               > ${REPORT_DIR}/inactive_arcs_${view}.rpt
    
    #####################
    # Reports that describe timing health
    #####################
    report_constraint -all_violators -view $view                                > ${REPORT_DIR}/allviol_${view}.rpt
    report_analysis_summary -view $view                                         > ${REPORT_DIR}/analysis_summary_${view}.rpt
    report_timing -view $view -path_type summary_slack_only -late -max_paths 5  > ${REPORT_DIR}/start_end_slack_${view}.rpt

    #####################
    # GBA Reports that show detailed timing
    #####################
    report_timing -view $view -late   -max_paths 50 -nworst 1 -path_type full_clock -net  > ${REPORT_DIR}/worst_max_path_${view}.rpt
    report_timing -view $view -early  -max_paths 50 -nworst 1 -path_type full_clock -net  > ${REPORT_DIR}/worst_min_path_${view}.rpt
    report_timing -view $view -path_type end_slack_only                       > ${REPORT_DIR}/setup_1_${view}.rpt
    report_timing -view $view -path_type end_slack_only  -early               > ${REPORT_DIR}/hold_1_${view}.rpt
    report_timing -view $view -late    -max_paths 100                         > ${REPORT_DIR}/setup_100_${view}.rpt.gz
    report_timing -view $view -early   -max_paths 100                         > ${REPORT_DIR}/hold_100_${view}.rpt.gz

    #####################
    # PBA Reports that show detailed timing
    #####################
    report_timing -view $view -retime path_slew_propagation -max_paths 50 -nworst 1 -path_type full_clock    > ${REPORT_DIR}/pba_50_paths_${view}.rpt

}
