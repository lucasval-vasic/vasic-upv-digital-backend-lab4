<img width="1334" height="324" alt="image" src="https://github.com/user-attachments/assets/e5847d12-fc9f-48a8-bc74-27ccf7422fc1" /># Lab 4 - Final checks

## Introduction
In this lab, we will run several verification steps on our implemented design to ensure it is ready for manufacturing. First, we will perform Design Rule Checking (DRC) to confirm that the layout adheres to all silicon foundry constraints. Next, we will conduct static timing analysis to verify that the design meets timing requirements with appropriate margins. Finally, we will perform binary equivalence checking to ensure that the generated netlist faithfully matches the intended functionality of the RTL design.

The lab includes files for the sync_fifo design, for the 0.18um X-Fab process. You will need data from all past labs as you will use tcons from Lab 1, synthesis files from Lab 2 and PNR files from Lab 3. If you complete all the lab you can also verify the async_fifo design.

## Lab evaluation
You are required to produce a lab report that documents the actions and experiments described in this guide. Present the results of your experiments using text, screenshots, or any other appropriate media.

## Evaluation rubric
The following breakdown shows how each section of this lab contributes to the overall marks:

- DRC checks. 1 point
- Parasitic extraction. 1 point
- Functional mode STA. 1 point
- MMMC STA setup. 1 point
- MMMC STA run and analysis. 1 point
- Signal Integrity (SI) analysis. 1 point
- Synthesis LEC good run. 1 point
- Synthesis LEC bad run. 1 point
- PNR LEC good run. 1 point
- PNR LEC good run. 1 point

## Lab start
As usual, we will source the config_cadence.sh script to set up the paths for Cadence flow:


```console
> source config_cadence.sh
```

## DRC checks
This section will perform design rule checks (DRC) on our design following the rules set by the manufacturing process provider (the X-Fab silicoun foundry). The starting point for this is the PnR run from Lab 3. You can either choose to run DRC checks on the Lab 3 folder or copy the pnr folder into this repository. We will run these checks from Innovus so the first step will be to start Innovus and  to restore the design from the final snapshot:

```console
> innovus
> source final.enc
```

### Connectivity checks
Here we will check whether all the nets and pins have proper connectivity. More specifically we will check whether some nets are floating, pins are shorted or open, or some nets were not routed. We can run these checks with the Innovus command:
```console
> verifyConnectivity
```

Since we have a completely routed and finalized design it is not expected that we see any of these violations.

### Geometry checks

Here multiple geometrical aspects of the design layout like shape width or spacing will be checked. The following Innovus command will perform this verification:

```console
> verify_drc
```

It is probable that you see multiple violations related to the filler cells. This is a known issue of the current flow. You can confirm this fact by loading the post-routing snapshot (source routing.enc) and rerunning the verifyGeometry command.

### Antenna checks
On this section we will check whether some metal tracks are long enough to be vulnerable to the antenna effect. Antenna rules in the runset file set constraints on the maximum track length per each of the metal layers. This command will check whether some of these rules are violated in our design:
```console
> verify_antenna
```

It is probable that you see some of these violations on your design (if you don't see any make sure you re-loaded the final PnR snapshot with source final.enc command). If this is the case you can use the GUI to observe the trace using the violation browser window. Click on an antenna violation and the GUI will automatically zoom to the affected track.

We can trigger a round of routing to try to remove these antenna violations. The Innovus router will initially attempt to perform layer hopping to remove the violations and if this is not possible attempt to insert antenna diodes on the affected metal track.

Use the following commands to run the router enabling options to solve the antenna issues:

```console
> setNanoRouteMode -drouteFixAntenna true
> setNanoRouteMode -routeInsertAntennaDiode true
> setNanoRouteMode -routeAntennaCellName ""
> globalDetailRoute
```

These commands instruct the router to try to fix the antenna violations with both metal hopping and antenna diodes insertion if required. Now run antenna checks again and confirm whether the violations are gone.

## Static Timing Analysis

Although we already spent some time on STA during Lab 1 here we will introduce concepts such as Multi-Mode Multi-Corner (MMMC) analysis or signal integrity (SI) analysis.

### Parasitic extraction

In order to perform an accurate analysis we need to run an initial parasitic extraction on our design. Innovus has the capability to perform signoff level parasitic extraction with these commands in order to produce an SPEF parasitic annotation file:

```console
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
```

You can execute these commands in the extract/scripts/extract.tcl script. After they execute check out the pnr/out directory to find the 2 SPEF files produced by Innovus, one per each manufacturing process corner.

Copy these SPEF files to sta/in folder so they can be later read by Tempus to annotate the parasitic components in the design.

### Initial run

We are now ready to perform our first STA analysis for today, we will need to exit Innovus, cd into sta/run folder and run Tempus. We will analyze our design on the 2 timing corners defined by the 0.18um manufacturing process: fast and slow. The sta folder of sync_fifo already contains the setup to run this mode except for the timing constraints file. Copy over the file from Lab 1 to tcons/ folder but modify the name to be sync_fifo_func.sdc (func stands for functional mode).

Execute the sta/run/sta.tcl script and observe the multiple reports. Notice how for each of the reports produced by STA in Lab 1 now we have 2 files, one per each of the process corners. Check out the equivalent file across both corners and notice how the propagation delays are different.

### Multi-Mode Multi-Corner analysis

Running a single analysis for our design will not adequately cover all the possible working modes. We are analyzing the functional mode but not other modes that the designs supports after implementation such as scan mode.

In order to support MMMC analysis we need to create 2 additional constraint files: one to analyze the scan shift cycle and one to analyze the scan capture cycle. These new timing constraints will be very similar to the functional ones except for the scan mode and scan enable settings that will be set with set_case_analysis commands. This table summarizes the val ues you will need to set in each of the files:

| mode         	 | scan_mode 	 | scan_enable 	 |
|----------------|-------------|---------------|
| functional   	 | 0         	 | 0           	 |
| scan_shift   	 | 1         	 | 1           	 |
| scan_capture 	 | 1         	 | 0           	 |

After creating the additional tcons files we need to tell Tempus to analyze these new modes. Open the sta/scripts/setup_mmmc.tcl script and find the line where the tcons file is used to create a constraint mode. Replicate this command twice, one to create a scan shift constraint mode and another one to create a scan capture constraint mode. Then on the next lines notice how functional analysis views for fast and slow corner are created. Replicate these commands to create analysis views for scan shift and scan capture, and make sure you include both corners.

Once the MMMC setup is complete you can rerun the sta.tcl script and notice now addition reports are created for the new scan modes. Review the reports to confirm that the setup was correct. As a hint on scan shift you should see timing paths that go from the flops Q outputs to the next flops SI inputs, and on scan capture you should see similar paths to the functional ones.

### Signal Integrity analysis

The STA setup will enable SI analysis by default but will not report the SI effects, we need to do this manually. Comment the "exit" command at the end of sta.tcl and re-run the analysis. Now use this customized report_timing to produce a new column incr_delay where the SI effects will be annotated:

```console
> report_timing -format {instance cell arc transition load delay incr_delay } -view fast_func
```

Check the new incr_delay column in timing report and notice that it adds no value most of the time. This is probably due to the fact that the design runs quite slow and the manufacturing process is quite large so SI effects are not very noticeable.

## Logical Equivalence Check

Here we will make use of the Cadence Conformal tool to perform out binary equivalence checks. The good news is that the synthesis and PNR tools automatically create the LEC setup for us. This setup takes the form of a .do script that we can execure in Conformal in a similar way to the TCL script we ran with Genus or Innovus.

### Synthesis checks

When we ran synthesis on Lab 2 we also created the LEC setup with the write_do_lec Genus command. In fact, we created 3 setups:

- RTL to synthesis netlist (rtl2final)
- RTL to synthesis intermediate (rtl2intermediate)
- Synthesis intermediate to synthesis final (intermediate2final)

The reason to these multiple setups is that sometimes due to the important optimizations done by Genus in datapath intensive designs it is not possible to run LEC between RTL and synthesis final gates so an intermediate verification step must be used. In our simple design this is not the case so we can simply run the rtl2final verification. There a caveat though: a type on the write_do_lec commands of scripts/write_outputs.tcl will attempt to load a non-existent netlist.

The bad commands are:

```console
write_do_lec -golden_design fv_map -revised_design ${OUTPUTS_PATH}/${BLOCK_NAME}_m.v -logfile  ${LOG_PATH}/intermediate2final.lec.log > ${OUTPUTS_PATH}/intermediate2final.lec.do
write_do_lec -revised_design ${OUTPUTS_PATH}/${BLOCK_NAME}_m.v -logfile ${LOG_PATH}/rtl2final.lec.log > ${OUTPUTS_PATH}/rtl2final.lec.do
```

Notice how the specified netlist  is not correct. If you intend to run synthesis again this should be fixed to:

```console
write_do_lec -golden_design fv_map -revised_design ${OUTPUTS_PATH}/${BLOCK_NAME}.vg -logfile  ${LOG_PATH}/intermediate2final.lec.log > ${OUTPUTS_PATH}/intermediate2final.lec.do
write_do_lec -revised_design ${OUTPUTS_PATH}/${BLOCK_NAME}.vg -logfile ${LOG_PATH}/rtl2final.lec.log > ${OUTPUTS_PATH}/rtl2final.lec.do
```

After either rerunning synthesis with the fixed command or renaming the expected netlist in syn/out to the ${BLOCK_NAME}_m.v we are ready to run LEC between RTL and synthesis gates. cd into the syn/run directory and invoke Conformal:

```console
> lec -do ../out/rtl2final.lec.do  -nogui -xl
```

If we analyze the output of this we can see that very detailed information is produced about the mapping and the compare points. Check the log/rtl2final.lec.log logfile to ensure you don't miss anything of the output. The key line is the one starting with "No of diff points", this prints out the number of non-equivalent points. If everything went well this should report 0 non-equivalent points.

Once you have seen the analysis pass try to modify either the netlist or the RTL code to produce non-equivalent points and the failure of LEC verification.
