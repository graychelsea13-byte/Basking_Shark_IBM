;;Overview BIG CHANGES in this version: 100 Sharks and sample zp now samples 20 patches



extensions [
             gis
             table
             csv

           ]


sharks-own [


            zp-list ;remembers the patches with high c. helgolandicus
            no-eat ;track the number of times in a row shark don't eat
            see-food? ; targeted food patch
            see-land? ; land patches in sense distance
            in-area?
            hidden ; number of days they've left the area
            start-season? ; count down till migration time
            migration ;radomly assigned number of days into the season to migrate into the model
            done-migrating? ;true/false if they've migrated in

           ]


breed [
             sharks ; C. maximus
             shark
      ]


patches-own [


             temperature ;sst
             patch-type ; takes on one of 3 values "water" "coastline" "land"
             land ;land
             shark-path ; track number of times sharks cross patch
             patchdate; set patchdate as a global variable to allow matching of dates between sst and zooplankton data
             lat; latitude
             long; longitude
             land-type ;coastal, open ocean, land
             coastal ;too close to land
             shark-visit ;sharks who have been in the patch--> need to make this a list I think....
             trail ;set hiking trails and beaches
             patch_cal ; raw number of calanus copepod
             patch_otherzp ; raw number of psuedo/Cent
             elev ;elevation
             num_sharks; number of sharks within a patch


          ]



globals [
             XC ; lat; from CSV
             YC ; long; from CSV
             sst; sea surface temp; from CSV
             date ;date; from CSV
             cal ;calanus (cal. fin and cal hel. from CPR data)
             other_zp ; psuedo and cent from CPR
             elevation ;from gebco map
             month; from CSV
             year; from CSV
             day; from CSV
             zpsamplelist ; CPR type sampling in model, to compare to real-world CPR data
             sharklist ;  creates csv of each shark's xy corrdinates at each time tick
             patch-data ; global sst/cpr/date variable for pulling into patch only
             sst_list ;sst csv
             zp ; zp csv
             hikers_list; random sampling to mimic sightings reports
             starting-seed



          ]



to setup
  ;file-close
  clear-all
  file-close-all
  set starting-seed new-seed
  random-seed starting-seed ;just to record this
  setup-map ;upload GEBCO map
  ask patches [  set shark-path 0 ]
  make-sharks ; Will make sharks, but not all will show at the start as they gradually migrate in

;read key data from CSV
  file-open "Data/cpr_SST_Netlogo_linear_interpolate.csv" ; open file with data on SST and zooplankton, one line will be read eadch tick.
  ;this is the file that contains the linear interpolation which replaces NAs with a guess based on linear interpolation
  let headers file-read-line ; read first line of headers to get out of the way

;set up csv export
  let a-row-list  ; psuedo CPR data sampling within in the model
          (list "date"
          "patch_cal"
          "patch_otherzp"
           "Total_Sharks" ;all sharks not marked "hidden"
           "single_sharks" );Number of sharks alone in a patch

          set zpsamplelist  ( list a-row-list)

  let a-row-list_shark (
          list
         "date"
         "lat"
         "long"
         "number_sharks";# sharks per aggregation
         "patch_cal"
         "patch_otherzp" ) ;
          set sharklist  ( list a-row-list_shark) ;track shark aggregations (defined as 2+)

  let   a-row-list-hiker ( ;randomly sample 10 patches of water, to mimic hiker and fisher submissions
            list
           "date"
           "lat"
           "long"
           "number_sharks"
           "patch_cal"
           "patch_otherzp")
         set hikers_list (list  a-row-list-hiker )



  ask sharks [set hidden 0 ] ;reset hidden count

  reset-ticks ; reset ticks & month
end

to setup-map
  ;; First - determine if patch is land, coastline, or openwater
  ;;56N -8 W 55 S -6.5 E
         ;Access bathymetric map of ocean (still using GEBCO map)
         set elevation gis:load-dataset "Data/gebco_2020_n56.0_s55.0_w-8.0_e-6.5.asc"  ; Load the raster data with elevation numbers
         gis:set-world-envelope-ds gis:envelope-of elevation ; Mapping envelope to NetLogo world
      ;  gis:paint elevation 200 ; Colors patches based on elevation data
         gis:apply-raster  elevation elev ; Copy elevation value from file to patch
         ;color the world based on elevation
         landset
         coastal-water
  ask patches [;set color of patches
             ifelse (elev > 0)
               [set patch-type "land"
                set pcolor green]
               [ifelse (coastal = 1)
                 [set patch-type "coastline" ;this helps sharks avoid land
                  set pcolor brown]
                  [set patch-type "openwater"
                   set pcolor blue]
               ]
           ]

  ;; Second - give patch latitude and longitude
  load-lat-long ;from csv



end

to landset ;;Hardcode when patch is land
            ;;;set the interior water bodies (ie lakes/rivers) as land
          ask patch  44 32  [ set elev  9 ]
          ask patch  44 30 [ set elev  9 ]
          ask patch 45 32  [ set elev  9 ]
          ask patch 44 32  [ set elev  9 ]
          ask patch 44 31  [ set elev  9 ]
          ask patch 18 24  [ set elev  9 ]
          ask patch 65 10  [ set elev  9 ]
          ask patch 66 10  [ set elev  9 ]
          ask patch 65 11  [ set elev  9 ]
          ask patch 18 20  [ set elev  9 ]
          ask patch 18 19  [ set elev  9 ]
          ask patch 18 18  [ set elev  9 ]
          ask patch 19 19  [ set elev  9 ]
          ask patch 19 18  [ set elev  9 ]
          ask patch 19 17  [ set elev  9 ]
          ask patch 20 17  [ set elev  9 ]
          ask patch 20 16  [ set elev  9 ]
          ask patch 20 15  [ set elev  9 ]
          ask patch 19 15  [ set elev  9 ]
          ask patch 19 14  [ set elev  9 ]
          ask patch 19 13  [ set elev  9 ]
          ask patch 19 12  [ set elev  9 ]
          ask patch 12 20  [ set elev  9 ]
          ask patch 12 22  [ set elev  9 ]
          ask patch 12 23  [ set elev  9 ]
          ask patch 13 22  [ set elev  9 ]
          ask patch 33 9 [ set elev  9 ]
          ask patches [ if elev > 0 [ set land 1 ]] ;mark which patches are land--> This is used in setup map procedure still, to run coastal-water in the ifelse color setting rules
end

to  coastal-water ;;Set coastal water for ZP growth and sharks avoiding land
          ask patches
          [ if any? patches with [land = 1 ] in-radius 1  [ ;distance arbitrary, failed attempt to keep sharks from swimming on land
              set coastal 1 ] ;mark which patches are close to land, to help sharks avoid them
  ]

end



to load-lat-long ; always one patch (Never the same) that has an error- it says its an error in file-read-line


     file-open "Data/LonLat.csv"  ; make sure this file is in the Data folder

     let headers file-read-line
        ;  print (word "There are the columns: " headers);
     let headlist csv:from-row headers
     let colcount length headlist
        ; print (word "this many columns: " colcount)
     let i 0

     repeat colcount [
                       let determ item i headlist
                          ;  print (word "column " i " is " determ)
                       set i ( i + 1 )
                      ]


     while [ not file-at-end? ]
             [
                 let nextline file-read-line
                 let mydata csv:from-row nextline
                                 ; print "==============================================" ; this printing might take longer, but leave for now
                                 ; print (word "next incoming line to process is: " nextline )
                                 ;  print mydata;
                 set XC item 0 mydata ;LOAD LAT
                 set YC item 1 mydata ;LOAD Long
                               ; print (word " data for patch (" XC ", " YC " )" ) ; this is where it stops working
                 let mytarget  one-of patches with [ pxcor = XC and pycor = YC ]
                 ask  mytarget
                     [
                        set  lat  item 2 mydata ;load lat
                        set  long  item 3 mydata ;load long
                      ]
              ]


  file-close

end

to make-sharks ;;semi- randomized localized start

; 150 sharks was the largest sighting (in Galway) --> assumed that not all sharks appeared, so raise the number in model to 200
;recent tests indicating that 100 sharks might be better

  create-sharks total_sharks [
                set shape "shark"
                set color gray
                set size 5

               year-set-sharks

               set zp-list [] ;initalize memory_prob of patches with high Calanus species
                  ]


end




to go

     tick
                           ;print word "**********************************************" date
      sst_import ; import SST and zp information
     ask patches [ set patchdate date] ;creates patch variable date
     ask sharks [  if month = 4 and day = 1   [ year-set-sharks]] ;reset sharks here; mimics seasonal migration
     migrate ; sharks randomly migrate into the model, instead of all appearing at once.
  ask patches with  [patch-type != "land" ]
                [
                  ifelse     (patch_otherzp + patch_cal)  > threshold_zp
                               [ set pcolor yellow]
                          [set pcolor blue]

                ] ; color patches based on the level of zooplankton

     set_zp ;import zooplankton from CSV file (CPR data)
     decide_path ;determine if patch has zooplankton > threshold_zp; if yes, next decision determined by model version
     track-no-eat; track number of days without food
     leave-season ;if # days without food (trak-no-eat) > no_eat_min (slider) sharks disapear
     landtrack; land patches track if sharks swam over them, for model implementation testing
     sample_zp; random sampling to mimic CPR (sort of)
     track-shark; create a csv of sharks
     hiker-report ; use patches to randomly sample areas, mimicking sightings reports

     rememberch ;remember patches with high zooplankton
     count-sharks-here ; count the number of sharks who share a patch
;    print count sharks with [hidden? = false]
;    print count patches with [num_sharks = 1 ]




      if year = 2018 and month = 10 and day = 26 [ exportSample ] ; export the CPR sampling
      if year = 2018 and month = 10 and day = 26 [ print "end run" stop ] ;auto stop at the end of 2018
;      ;due to issues with CPR data & and interpolation, just end on 10/26/18


;     ;;shorter runs just for testing purposes
;     if year = 1982 and month = 10 and day = 31 [ exportSample ] ; export the CPR sampling
;     if year = 1982 and month = 10 and day = 31 [ print "end run" stop ] ;auto stop at the end of 2018


;      if year = 2000 and month = 10 and day = 26 [ exportSample ] ; export the CPR sampling; early end for behavior space tests
;      if year = 2000 and month = 10 and day = 26 [ print "end run" stop ] ;auto stop at the end of 2000

end

to exportSample ; psuedo CPR sampling within the model, export as excel sheet.

 ;creates csv of each shark's xy corrdinates at each time tick
      csv:to-file (word "zp_sample_" behaviorspace-experiment-name behaviorspace-run-number"_.csv" ) zpsamplelist ;psuedo CPR sampling
      csv:to-file (word "shark_list_" behaviorspace-experiment-name behaviorspace-run-number"_.csv" ) sharklist ;track all aggregations of sharks of 2 or more
      csv:to-file (word "hiker_report_" behaviorspace-experiment-name behaviorspace-run-number "_.csv" ) hikers_list ;randomly sample patches and "report" sightings

end


to sst_import ; uploads SST from CSV file that contains all the years daily average sst and the date info
;this has no pact on the model at the moment, but it can be used for data analysis purposes
  ;SST comes from https://marine.copernicus.eu/access-data/ocean-monitoring-indicators/baltic-sea-surface-temperature-cumulative-trend-map

    if file-at-end? [ stop ]
    let row csv:from-row file-read-line
    set date item 0 row
    set sst item 1 row
    set year item 2 row
    set month item 3 row
    set day item 4 row ;for the final, total SST file to be made in R
    set other_zp item 5 row
    set cal item 6 row


end



;;------------------------SHARK SETUP PROCEDURES------------------------;;



to year-set-sharks  ;this procedure is repeated every year

      ask sharks [set migration one-of (range 0 60) ;set random wait time for when sharks will migrate into the area at the start of the season
      set start-season? 0 ;set season counter
      move-to one-of patches with[(patch-type = "openwater" and pxcor < 30) or (patch-type = "openwater" and pxcor > 65 ) or (patch-type = "openwater" and pycor > 80)];randomly distribute in East and West; to represent coming from the atlantic or from the irish sea
      set no-eat 0 ;reset yearly eat counter
      set hidden 0 ;ensure the hidden count is reset
      set hidden? TRUE ;hide all sharks to start off with
      set done-migrating? FALSE ;set sharks to still be migrating in
      ]

end

 to migrate ;in go procedure

      ask sharks [
      if done-migrating? = FALSE [ ;if they haven't migrated in yet
           set start-season? start-season? + 1 ;count number of days in the seas

            ifelse start-season? > migration ; when radomly chosen migration time is met

                 [set hidden? FALSE  ;stop hiding
                 set done-migrating? TRUE]  ; migrate into model and start swimming
                 [set hidden? TRUE ] ;if haven't reached migration date, stay hidden
      ]]


end

;;------------------------SHARK GO PROCEDURES------------------------;;

to rememberch ;keep track of patches with high zooplankton


  ask sharks [
    if [(patch_otherzp + patch_cal)] of patch-here > (threshold_zp * 3) ;and [num_sharks] of patch-here < 2

                 [
                            let a-row-list_cal ( list
                            patch-here)

                             set zp-list lput a-row-list_cal  zp-list
                   ]

  ]
ask sharks [set zp-list remove-duplicates zp-list]; print word "remove duplicates" self] ;remove duplicates from the zp-list

end



to decide_path ;same for all model versions,
  ;shark determines if there is sufficient food to stay of if they need to leave
  ;need this for friend version as well, or else once they find each other, they never leave.


  ask sharks [ if hidden? = FALSE [
;                                      print word "============STARTING LOCATION==========" (patch-here)
;                                      print  self

      let countsharks (num_sharks * threshold_zp) ;this would calculate enough to support the number of sharks in the patch
       if countsharks = 0 [set countsharks 1] ;prevents division by 0 error

    ifelse  [ (patch_otherzp + patch_cal) / countsharks] of patch-here   < threshold_zp


    [if model-version = "friends" [
      ;print "GO TO FIND FRIEND" ;print self
      find-friend
       ] ;seek only other sharks

    if model-version = "both"  [
         ;print "go to hunt cop BOTH" ;print self
        hunt_copepod ;note that at the end of hunt_copepod will send them to find friends if they don't find copepods; if they don't find food they look for friends then use the memory

      ]; see both sharks and copepods


    if model-version = "memory_shark"  [
        ;print "go to hunt cop MEMSHARK" ;print self
        hunt_copepod

      ] ; sek only copepods, including a memory parameter

    ]
    [ ;print word "++++++++++++++stay put+++++++++++++" self
    ]
  ]]





end


to find-friend ;seek other sharks

   let list_clear? FALSE ;is there a list of potential patches?
   let hunting? TRUE ;Is the shark able/need to hunt still?


   let possible-targets patch-set patches in-radius (sense-distance * 2) with [ patch-type != "land"  and num_sharks >= friend_min  ]  ;create a list of targets-- all potential patch options
  ;assume sharks can sense sharks at a larger distance than zooplankton, so sense-distance * 2
                                    ;print word "possible-targets-friendss" self
                                    ;print possible-targets
   let  possible-targets_sort reverse sort-on [ num_sharks  ] possible-targets ;sorts in descending order by number of sharks
                                    ;print word "possible-targets_sort " self
                                    ;print possible-targets_sort


  if empty? possible-targets_sort = FALSE[     if first possible-targets_sort = patch-here  [set possible-targets_sort remove-item  0 possible-targets_sort ]];choose just one target, from the top of the list, sorted by amount of sharks
        ;this is needed because in this section, they can choose the patch they're in to stay in if there are sufficient sharks, regardless of food
    ;if empty? possible-targets_sort = TRUE [set hunting? False ] ;in case removing the patch-here results in an empty list
      if empty? possible-targets_sort = TRUE [set hunting? False   ;if there are no possible targets (list empty) can no longer hunt
                                   ;print word "hunting false skip while" self
  ];

  while [  hunting? = TRUE and list_clear? = FALSE]
  [


                                                 ;print "inside hunting while loop"


           let target_friend first possible-targets_sort ;choose just one target, from the top of the list, sorted by amount of sharks
                                                ;print word "target_friend" self
                                                ;print target_friend



           face target_friend ;face target patch
                                            ;print word "face target_cal" self;face the target This error message--> FACE expected input to be an agent but got the agentset (agentset, 1 patch) instead.
           let clear? true ;set the pathway as clear
                                            ;print word "let clear true" self;something breaks here and the shark will repeat selecting a target_cal --> See below "Example of hunt_cal clear glitch"

           let i 1 ;this is for checking if there are obstacles in the path
                                    ;print "let i 1"
           let view_patch patch-ahead 1
                                   ;print (word "view_patch is " view_patch) ;see below for comments add later


                                                  ;print word "Entering interior while loop" self



           ;print  "target friend should be different then patch-here"
           while [view_patch != target_friend and view_patch != nobody and clear? = TRUE] ;sort through patches to identify if land is there
                   [

                       ;if target_friend = patch-here [set clear? TRUE]

                                                                  ;print word "setting not-target? false" self

                                    if [patch-type] of view_patch = "land" [
                                      set clear? false
                                                                   ;print word "setting clear to false l.789" self
                                    ]
                                    set i i + 1
                                    set view_patch patch-ahead i
                                    if view_patch = target_friend [set clear? TRUE]
                                   ; if distance view_patch >= sense-distance [set clear? TRUE]
                                                                 ;[set not-target? FALSE set clear? TRUE]
                                                                  ;print (word "view_patch is " view_patch self)
                                  ] ; end of while [view_patch != target_cal and view_patch != nobody and clear? = TRUE]

                                                          ;print word "Exiting interior while loop" self
                                                          ;print (word " line 797 clear? is " clear? self)

      ;print  "skip land search"
                       ifelse clear? = true
                     [
                                          ;print word "clear true" self
                          set possible-targets_sort no-patches
                                  ;print word "possible-targets set to no-patches" self
                                  ;print (word "possible targets: " possible-targets self)
                                  ;print word "cleared list cal" self
                          set list_clear? TRUE ;Differentiate between an empty possible-target list because of a target patch, versus there being no patches
                                 ;print word "set list_clear? TRUE line 580" self

                                  ; ;print "clear false to end while loop"
                        if distance target_friend <= swim-speed
                            [move-to target_friend]
                                                 ;   ;print word "=============================moved to target_cal" self  ;print (patch-here) ]
                                                     ;print (word "move-to target FRIEND :" self patch-here ) ;126 pink
                        if distance target_friend > swim-speed
                           [face target_friend fd swim-speed]; ;print (word "swim to target cal:" self  )  ;print (patch-here) ] ; radius 3.75= avg. daily travel distance; round up to 4 becuase they wont eat 24 hours straight


                       ]
                                                  ;if patch is clear, erase list and focus on target patch now
                   [

                     set possible-targets_sort remove-item  0 possible-targets_sort ;since list is sorted by maximum pactch_cal, you can just remove item 0
                     if empty? possible-targets_sort = TRUE [set hunting?  FALSE
                        ;print "setting list clear false line 750"
                             ]


               ]


  ]

   if hunting? = FALSE  [

         if model-version = "friends" [
            ;print word "go to random-move MODEL VERSION FRIEND" self
           random-move
           ] ;friend only moves directly to random

        if model-version = "both" [
         ;print word "go to hunt-shark-memory MODEL VERSION NO BOTH" self
         hunt-shark-memory ;no food, no friends in sight,  go through memory of high zooplankton

       ]] ;model version both moves from friend to memory


end

to hunt_copepod ;hunt zooplankton


   let list_clear? FALSE
   let hunting? TRUE


   let possible-targets patch-set patches in-radius sense-distance with [ patch-type != "land"  and (patch_cal + patch_otherzp) >= threshold_zp ]
     ;create a list of targets-- all potential patch options
                                   ;print word "possible-targets" self
                                   ;print possible-targets
   let  possible-targets_sort reverse sort-on [patch_cal] possible-targets ;sorts in descending order by amount of zooplankton
                                    ;print word "possible-targets_sort " self
                                    ;print possible-targets_sort

     if empty? possible-targets_sort = TRUE [set hunting? False ]

  while [  hunting? = TRUE and list_clear? = FALSE]
             [ ;while a list exists, use "any?" not NOBODY for agentsets
                                                ;print "inside hunting while loop"
               let target_other first possible-targets_sort ;choose just one target, from the top of the list, sorted by size
                                                ;print word "target_other" self
                                                ;print (word "possible targets: " possible-targets)
                                                ;print (word "target patch: " target_other)


            face target_other
                                 ;          ;print word "face target_cal" self;face the target This error message--> FACE expected input to be an agent but got the agentset (agentset, 1 patch) instead.
            let clear? true
                               ;          ;print word "let clear true" self;something breaks here and the shark will repeat selecting a target_cal --> See below "Example of hunt_cal clear glitch"

            let i 1
                                 ;  ;print "let i 1"
            let view_patch patch-ahead 1
                                      ;print (word "view_patch is " view_patch) ;see below for comments add later


                                                   ;print word "Entering interior while loop" self
                 while [view_patch != target_other and view_patch != nobody and clear? = TRUE] [
                            if [patch-type] of view_patch = "land" [
                              set clear? false
                                                             ;print word "setting clear to false l.789" self
                            ]
                            set i i + 1
                            set view_patch patch-ahead i
                                                            ;print (word "view_patch is " view_patch self)
                          ] ; end of while [view_patch != target_cal and view_patch != nobody and clear? = TRUE]

                                            ;print word "Exiting interior while loop" self
                                            ;print (word " line 797 clear? is " clear? self)


                 ifelse clear? = true
                      [
                                           ;print word "clear true" self
                           set possible-targets_sort no-patches
                                                             ;print word "possible-targets set to no-patches" self
                                                             ;print (word "possible targets: " possible-targets self)
                                                             ;print word "cleared list cal" self
                           set list_clear? TRUE ;Differentiate between an empty possible-target list because of a target patch, versus there being no patches
                                                          ;print word "set list_clear? TRUE line 679" self

                                                          ; ;print "clear false to end while loop"
                          if distance target_other <= swim-speed
                                   [move-to target_other
                                    ;print word "moved to target_cal" self  ;print (patch-here)
                                   ]
                                                      ; ;print (word "move-to target cal:" self  ) ;126 pink
                          if distance target_other > swim-speed
                                   [face target_other fd swim-speed
                                    ;print (word "swim to target cal:" self  )  ;print (patch-here)
                                   ] ; radius 3.75= avg. daily travel distance; round up to 4 becuase they wont eat 24 hours straight


                                      ]
                                             ;if patch is clear, erase list and focus on target patch now
                          [

                      set possible-targets_sort remove-item  0 possible-targets_sort ;since list is sorted by maximum pactch_cal, you can just remove item 0
                     if empty? possible-targets_sort = TRUE [set list_clear? TRUE]; ;print "setting list clear false line 789"]



                          ]



           ]

if hunting? = FALSE [

         if model-version = "both"  [
            ;print word "go to find-friend MODEL VERSION BOTH" self
           find-friend
           ] ;model version noth goes to the find friend version next, then memory, then random

         if model-version = "memory_shark"  [
           ;print "go to memory MODEL VERSNO MEM SHARK" ;print self
           hunt-shark-memory
       ]] ;model version memory goes to the memory funciton, then to random


end


to hunt-shark-memory ;based on zp-list, which sharks use to keep track of patches with high zooplankton
;;print word "in-shark memory" self
;remember that you have to use "one-of" because of the zp-list, i.e. 'one-of target' instead of 'target'
  ifelse length zp-list > 5 [
             let possible-targets sort-by [[ mem1 mem2 ] -> (distance first mem1) < (distance first mem2) ] zp-list
                                          ;print word "possible targets sorted distance" possible-targets  ;print self
                                         ;print first possible-targets



    ;print word "possible targets sorted distance" possible-targets  ;print self


             let list_clear? FALSE
             let hunting? TRUE
              if length zp-list < 5 [set hunting? False and list_clear? = FALSE

                                    ;print word "clearing zp list" self
                                    ]

              if length possible-targets < 5 [set hunting? False and list_clear? = FALSE  ]
              if empty? possible-targets = TRUE [set hunting? False ]

                              ;print length possible-targets
                              ;print possible-targets

                       while [  hunting? = TRUE and list_clear? = FALSE ] [
                                                           ;print "inside while loop memory"
                       let target_sharkmem item 0 possible-targets; choose closest patch

                              if one-of target_sharkmem  = patch-here
                                    [set possible-targets  remove-item  0 possible-targets  ;        ;this is needed because in this seciton, they can choose the patch they're in to stay in if there are sufficient sharks, regardless of food
                              ;print word "removing item 1 list" self
                                 ]
                      set  target_sharkmem item 0 possible-targets; choose closest patch
                                                              ;print length target_sharkmem
                                                             ;print word "Target_remembered" self
                                                               ;print (word "possible targets memory list: " possible-targets)
                                                             ;print (word "target patch memory : " target_sharkmem)


                       face  one-of target_sharkmem ;have to use "one-of" even tho there is only one bc netlogo still recognizes this as a list
                         ;print one-of target_sharkmem
                                                        ;print word "face target_cal" self;face the target This error message--> FACE expected input to be an agent but got the agentset (agentset, 1 patch) instead.
                         let clear? true
                                                      ;print word "let clear true" self;something breaks here and the shark will repeat selecting a target_cal --> See below "Example of hunt_cal clear glitch"

                         let i 1
                                                ;print "let i 1"
                         let view_patch patch-ahead 1
                                                   ;print (word "view_patch is " view_patch) ;see below for comments add later


                                                  ;print word "Entering interior while loop" self
                              while [view_patch != one-of target_sharkmem and view_patch != nobody and clear? = TRUE]
                   [

                       ;if target_sharkmem = patch-here [set clear? TRUE]

                                                                  ;;print word "setting not-target? false" self

                                    if [patch-type] of view_patch = "land" [
                                      set clear? false
                                                                   ;print word "setting clear to false l.789" self
                                    ]
                                    set i i + 1
                                    set view_patch patch-ahead i
                                    if view_patch = one-of target_sharkmem [set clear? TRUE]
                                   ; if distance view_patch >= sense-distance [set clear? TRUE]
                                                                 ;[set not-target? FALSE set clear? TRUE]
                                                                  ;print (word "view_patch is " view_patch self)
                                  ] ; end of while [view_patch != target_cal and view_patch != nobody and clear? = TRUE]

                                                          ;print word "Exiting interior while loop" self
                                                          ;print (word " line 797 clear? is " clear? self)

      ;;print  "skip land search"
                                      ifelse clear? = true
                                   [
                                                                   ;print word "clear true" self
                                        set possible-targets  NOBODY
                                                                           ;print word "possible-targets set to no-patches" self
                                                                          ;print (word "possible targets: " possible-targets self)
                                                                           ;print word "cleared list cal" self
                                        set list_clear? TRUE ;Differentiate between an empty possible-target list because of a target patch, versus there being no patches
                                                                       ;print word "set list_clear? TRUE line 779" self

                                 ; ;;print "clear false to end while loop"
                         if distance one-of target_sharkmem <= swim-speed + 1  [move-to one-of target_sharkmem
                                                                                ;print word "moved to target mem" self  ;print (patch-here)
                                                                                 ]

                         if distance one-of target_sharkmem > swim-speed + 1         [face one-of  target_sharkmem fd swim-speed + 1

                                                                             ;print (word "swim to target mem:" self  )
                                                                            ;print (patch-here)
                                                                                  ]
                                 ]

                                  [

                          set possible-targets remove-item  0 possible-targets ;if patch is clear, erase list and focus on target patch now
                           if length possible-targets < 5 [set hunting? False and list_clear? = FALSE ; ;;print word "removing item 0 memry" self
                           ];remove closet patch if can't get to it
                         if  possible-targets = NOBODY [set list_clear? TRUE]; ;;print "setting list clear false line 789"]
                                  ]
                              ]

    if hunting? = FALSE [random-move
      ;print word "hung prob zp from shark memory, go to random move" self

    ]; ;;print word "random-move within memory" self]
;this code is different because the memory list acts differently than a temperary list like the other procedures have
  ]

  [random-move  ;have this twice because the action starts with an ifelse for the length of the zp=-list
    ;print word "random-move skip memory list < 5 " self
  ] ;skip the whole thing if zp-list is too short



End





to random-move



                                   ;print word "random-mve"self
                                   ;  print "-----------------------Random move------------------------"
                                   ;  print (word "shark location is " xcor " " ycor)
                                   ;    setxy (round xcor) (round ycor)
                                   ;  print (word "shark location is " xcor " " ycor)

   let list_clear? FALSE


  let possible-targets patch-set patches in-radius sense-distance   with [ patch-type != "land" ];create a list of targets-- all potential patch options

    while [any? possible-targets != FALSE ] [ ;while a list exists, use "any?" not NOBODY for agentsets
      let target_both one-of possible-targets ;choose just one target
                                   ;  print (word "possible targets: " possible-targets)
                                   ;  print (word "target patch: " target_both)
      let old_targets patch-set target_both ;create list of already targeted patches
                                   ;  print (word "old targets: " old_targets)

      face target_both
                                   ;  print "face target_random";face the target This error message--> FACE expected input to be an agent but got the agentset (agentset, 1 patch) instead.
      let clear? true
                                   ;  print "let clear true";something breaks here and the shark will repeat selecting a target_cal --> See below "Example of hunt_cal clear glitch"

      let i 1
                                   ;  print "let i 1"
      let view_patch patch-ahead 1
                                   ;  print (word "view_patch is " view_patch) ;see below for comments add later


                                   ;  print "Entering interior while loop"
      while [view_patch != target_both and view_patch != nobody and clear? = TRUE] [
              if [patch-type] of view_patch = "land" [
                set clear? false
                                   ;        print "setting clear to false"
              ]
              set i i + 1
              set view_patch patch-ahead i
                                   ;        print (word "view_patch is " view_patch)
            ] ; end of while [view_patch != target_cal and view_patch != nobody and clear? = TRUE]

                                   ;       print "Exiting interior while loop"
                                   ;       print (word "clear? is " clear?)


             ifelse clear? = true
               [
                                   ;          print "clear true"
                set possible-targets no-patches
                                   ;                        print "possible-targets set to no-patches"
                                   ;                        print (word "possible targets: " possible-targets)
                                   ;                        print "cleared list random"
                set list_clear? TRUE
                                            ;       set clear? false
                                            ; print "clear false to end while loop"
        ifelse distance target_both <= swim-speed + 1 [move-to target_both];print (word "move to target random:" self  )]  ;assumed they move faster when not eating
                                        [face target_both fd swim-speed + 1 ]; print (word "toward target random:" self  ) ]
                                   ;                        print "moved to target patch random"
               ]
                            ;if patch is clear, erase list and focus on target patch now
               [;set possible-targets other old_targets
                 set possible-targets possible-targets with [not member? self old_targets]
                                   ;         print (word "possible targets: " possible-targets)
                                            ;show possible-targets
                                            ;print "old targets:"
                                            ;show old_targets
        if any? possible-targets = FALSE [set list_clear? TRUE ]
                                   ;         print "removed item random"
               ]
           ] ; end of while [any? possible-targets != FALSE ]






end





to track-no-eat ; sharks determine when to migrate out of  model, leaving for the UK and other locales
  ;track the number of days that sharks don't "eat" zooplankton (have patches < threshold_zp)
  ask sharks [ ;track consecutive days without enough food
             ifelse  [ (patch_otherzp + patch_cal)] of patch-here < (threshold_zp / 2)  ;doesn't count number of sharks, but just to give sharks the idea of a decline in zooplankton
              [ set no-eat no-eat + 1]
                  ; print "not eat"
              [ set no-eat 0 ]
             ]

end

to leave-season ;this mimics sharks leaving for other foraging waters
  ;leave after no-eat limit reached
  ;this works faster than when I tried using while loops. This is probably not the most efficient method, but it's workable.

  ;return-season = slider for how many days they leave the area before returning
  ask sharks [ifelse no-eat > no_eat_min ; no_eat_min = slider
    [
      ;print (word "leave season" self)
      set in-area? FALSE   ]
    [ set in-area? TRUE]]

  ask sharks [ if in-area? = FALSE
    [set hidden? TRUE
     set hidden hidden + 1  ] ] ;count number of days hidden, to compare against return-season

  ask sharks [if hidden = return-season [  ;return-season = slider; number of days before they migrate back in
    move-to one-of patches with [(patch-type = "openwater" and pxcor < 30) or (patch-type = "openwater" and pxcor > 65 ) or (patch-type = "openwater" and pycor > 80)] ;assumed they migrated toward hebrides and may be returning from that direction
    set in-area? TRUE
    set hidden? FALSE
    ;set color pink
    set hidden 0 ]]; print (word "return season" self)] ] ;they return to the spot they disapeared at.

end






to count-sharks-here ;keep track of number sharks in patch
;set as patch characteristic to smooth out errors where sharks with hidden?= TRUE are counted



ask patches  with [patch-type != land][
    let shark_count count sharks-here with [ hidden? = FALSE ]
    set num_sharks shark_count]


end



;;------------------------PATCH GO PROCEDURES------------------------;;





to set_zp ;distribute zooplankton throughout water patches
  ;randomly distribute zooplankton amounts in the set % of patches

ask patches [set patch_cal 0 ] ;erase prevoius zooplankton

 let avg_patch_cal  (cal / 3 ) * 10000000 / (Cal_% / 100)  ; assuming all copepods are in the top ten meters of water; CPR data = 3m^3; cpr data = 10 nm  18 km (patch = 1 km)
; divide by 3 because CPR 3m^3, each patch is 10000000m^3
  let upwell  patches with [ patch-type != "land"]; and elev > -70 ] ; and add elev later  ;only grow in

  ask upwell [
    ifelse (random-float 1 <  (Cal_% / 100))

    [set patch_cal max list 0 ( random-normal avg_patch_cal (0.1 * avg_patch_cal)) ] ;cal sd: 46984.16 --> this is daily SD; make SD = 1/10 of avg patch cal

    [set patch_cal 0 ]
      ]

;;;###placeholder for other zp to code combined counts of total zooplankton for sharks
  let avg_patch_otherzp  (other_zp / 3 ) * 10000000 / (other_zp_% / 100)  ; assuming all copepods are in the top ten meters of water; CPR data = 3m^3; patches = 0.01km^3

  ask upwell [
    ifelse (random-float 1 <  (other_zp_% / 100))

    [set patch_otherzp max list 0 ( random-normal avg_patch_otherzp (0.1 * avg_patch_otherzp)) ]

    [set patch_otherzp 0 ]
      ]

end
  ;otherzp sd: 6620.723
  ; cal sd: 46984.16


to color-set ;set patch color

ask patches [ if patch-type = "coastline" and land = 0 [
                   ifelse patch_cal < 1 [set pcolor brown]  [ set pcolor white]]
            ]

ask patches [ if patch-type = "openwater" and land = 0 [
                ifelse patch_cal < 1 [set pcolor blue]  [ set pcolor white]]
             ]


end


;------visual debugging --------


to landtrack ;still in go to catch any errors
  ;tracks when sharks swim in land for visual debugging


  let nogo  patches with [ patch-type = "land" ]
  ask nogo [if  any? sharks-here [set shark-path shark-path + 1  set pcolor orange ]]


end

to track-sharks-route ;visual trace of patches sharks have been to for debugging (not in go)
           ask patches [if any? sharks-here [set shark-path shark-path + 1  set pcolor yellow ]]  ;count the number of sharks that have been in a patch


           ask patches [
                        if any? sharks-here [set shark-visit fput ( list [who] of  sharks-here ) shark-visit ;keep a list of which sharks have visited which patch
                                            ]
                         ]


end


;;----------external monitors------;;



to count_cal
    show count patches with [patch_cal > 0 ]

end


to hiker-report
  ;randomly sample patches to mimic sightings reports. Only report if there is a shark.
  ; hikers as agents  REALLY slows down the model
let sample n-of 20 patches with [patch-type != land]

  ask sample[ if num_sharks > 0 [  let a-row-list-hiker (
  list
          date
          lat
          long
          num_sharks
          patch_cal
          patch_otherzp

    )
     set hikers_list lput a-row-list-hiker hikers_list

  ]]


end


to sample_zp;;mimic CPR sampling to assess reliability of zooplankton in the model

let sample n-of 10 patches with [patch-type != land]
  let a-row-list (list date mean [patch_cal] of sample
           mean [patch_otherzp] of sample ;average daily zooplankton
           count sharks with [hidden? = false]; count total sharksin the model
           count patches with [num_sharks = 1 ] ;count single sharks
  ) ; automatically mean sample
   set zpsamplelist lput a-row-list zpsamplelist


end


to track-shark ;shark makes list of location that is exported to a csv file

    ;xcor and ycor automatically updated, can be fractions of patches
    ;move to sends fish to center of patch; so our turtles will have whole numbers

  let aggregate-patches patches with [num_sharks > 1 ]
  ask aggregate-patches [
  let a-row-list_shark (
      list
      date
      lat
      long
      num_sharks
      patch_cal
      patch_otherzp
    )
    set sharklist lput a-row-list_shark sharklist
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
321
62
676
476
-1
-1
3.653
1
10
1
1
1
0
0
0
1
0
94
0
110
1
1
1
ticks
30.0

BUTTON
26
402
89
435
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
109
356
172
389
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
855
33
921
78
Cal
count patches with [patch_cal > 0 ]
17
1
11

CHOOSER
18
19
185
64
model-version
model-version
"both" "memory_shark" "random" "friends"
3

MONITOR
856
84
922
129
Other zp 
count patches with [ patch_otherzp > 0 ]
17
1
11

PLOT
1042
265
1435
446
Number Sharks Shoaling
Week
# sharks
0.0
10.0
0.0
10.0
true
true
"\n" ""
PENS
"Sharks Aggregating" 1.0 0 -10873583 true "" "plot count patches with [num_sharks > 1]"
"Total Sharks" 1.0 0 -7500403 true "" "Plot count sharks with [hidden? = FALSE]"
" > 5" 1.0 0 -15040220 true "" "Plot count patches with [num_sharks > 5]"
"> 10" 1.0 0 -14730904 true "" "Plot count patches with [num_sharks > 10]"
"> 20" 1.0 0 -2674135 true "" "Plot count patches with [num_sharks > 20]"

SLIDER
10
132
182
165
threshold_zp
threshold_zp
0
1000000000000
3.0E12
1
1
NIL
HORIZONTAL

MONITOR
1043
40
1172
85
# patches w Aggregations
count patches with [num_sharks > 1 ]
17
1
11

BUTTON
99
401
197
434
NIL
reset-ticks\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
526
10
621
55
Total Patches
count patches
17
1
11

MONITOR
1174
40
1264
85
Count Total Sharks
count sharks with [hidden? = false]
17
1
11

SLIDER
13
90
181
123
sense-distance
sense-distance
0
100
10.0
1
1
NIL
HORIZONTAL

MONITOR
356
10
437
55
Date
date
17
1
11

MONITOR
454
10
515
55
SST
sst
2
1
11

MONITOR
931
139
1035
184
Loaded Lat/Long
count patches with [lat > 0 ]
17
1
11

MONITOR
929
33
1007
78
No Cal
count patches with [ patch_cal = 0 ]
17
1
11

SLIDER
201
104
301
137
Cal_%
Cal_%
0
100
17.0
1
1
NIL
HORIZONTAL

SLIDER
201
142
301
175
other_zp_%
other_zp_%
-1
100
17.0
1
1
NIL
HORIZONTAL

MONITOR
1279
41
1353
86
LandShark
count patches with [patch-type = \"land\" and shark-path > 0 ]
17
1
11

SLIDER
10
172
182
205
No_eat_min
No_eat_min
0
100
14.0
1
1
NIL
HORIZONTAL

BUTTON
27
353
93
387
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
849
138
925
183
both ZP
count patches with [ patch_otherzp > 0 and patch_cal > 0  ]
17
1
11

MONITOR
689
99
811
144
Cal > threshold
count patches with [patch_cal > threshold_zp]
17
1
11

MONITOR
688
49
811
94
Total zp > threshold
count patches with [(patch_cal + patch_otherzp) > threshold_zp]
17
1
11

TEXTBOX
54
72
146
90
Shark Variables
11
0.0
1

TEXTBOX
209
71
315
113
Set % Patches \nwith Zooplankton\n
11
0.0
1

TEXTBOX
873
11
1001
40
Count patches with...\n
11
0.0
1

TEXTBOX
1149
10
1299
28
Monitor Shark Variables\n
11
0.0
1

PLOT
1038
103
1380
248
Avg Zooplankton
Date
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Cal" 1.0 0 -12345184 true "" "plot mean [patch_cal] of patches with [patch-type != \"land\" ]"
"Other_Zp" 1.0 0 -4699768 true "" "plot mean [patch_otherzp] of patches with [patch-type != \"land\" ]"

TEXTBOX
697
13
816
41
Monitor # of patches \nabove Threshold_zp\n
11
0.0
1

MONITOR
688
150
814
195
otherzp > Threshold
count patches with [patch_otherzp > threshold_zp]
17
1
11

MONITOR
928
86
1006
131
No otherzp
count patches with [ patch_otherzp = 0 ]
17
1
11

SLIDER
8
215
180
248
return-season
return-season
0
100
6.0
1
1
NIL
HORIZONTAL

SLIDER
199
187
301
220
friend_min
friend_min
0
100
5.0
1
1
NIL
HORIZONTAL

PLOT
705
219
988
401
large ags
NIL
NIL
0.0
10.0
0.0
10000.0
true
true
"" ""
PENS
"> 10" 1.0 0 -16777216 true "" "Plot count patches with [num_sharks > 10]"
"> 20" 1.0 0 -7500403 true "" "Plot count patches with [num_sharks > 20]"

MONITOR
833
429
930
474
NIL
starting-seed
17
1
11

SLIDER
7
260
182
293
swim-speed
swim-speed
0
100
9.0
1
1
NIL
HORIZONTAL

SLIDER
203
235
303
268
total_sharks
total_sharks
0
100
200.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
Updated August 2023

## WHAT IS IT?
This model seeks to reproduce basking shark aggregation behavior in Ireland and to test what environmental and/or behavioral drivers lead to shark aggregations. The model reproduces a 10,545 km2 area around the Inishowen Peninsula of Ireland, divided into 1km2 patches which reflect only the top 10 meters of water.  

## HOW IT WORKS

<b>Model Timing</b>
The model operates under a 24-hour time step, meaning that each time the model updates, 24 hours have passed. The model runs from April 1982 to October 2018. The model only depicts the months between April and October, as sharks are not present at the surface of Irish waters during the other months. 

<b>Zooplankton</b>
Each model day, zooplankton are distributed throughout the model. The zooplankton estimates are extrapolated from data from the Continuous Plankton Recorder. As this data is limited, missing data points have been estimated using a linear interpolation. The average of the zooplankton population is updated each day from the CPR data, but the percentage of patches with zooplankton are set by the user (Cal_% and otherzp_%). The input data of zooplankton differentiates Calanus copepods from other species of zooplankton, as basking sharks are documented to prefer Calanus copepods (Sims 2008). 

The user sets the minimum foraging level of zooplankton (threshold_zp) a patch must contain for a shark to either remain in the patch or select a patch move to. 

<B>Public Reports</b>
Every day, 20  patches are randomly selected and sampled. The number of sharks in each sampled patch is recorded. This is to mimic reports from boaters and hikers. Data is only recorded if sharks were seen. 

<b>Shark Movement</b>

At the start of each season, sharks are assigned a random number of days (between 0 and 60) to wait before entering the model. When they first enter the model, they are distributed in the edges of the model, to mimic “swimming” into the area. 

Sharks can “see” a distance set by the user (sense-distance). Sharks will select patches in their sense-distance to move to. 

Each day, Sharks make a decision where to move. While there are five different model version, in all models (except Random) the first decision a shark makes is whether or not to leave the area they currently reside. They will only do so if the total amount of zooplankton in their 1km2 area, when divided by the number of sharks present, is below the threshold level of zooplankton. 

If sharks can’t find any patches that fulfill the requirements to move to a patch (set by model versions), they will swim at random. 

Sharks will “migrate” out of the model area if they do not find patches with the threshold level of zooplankton. The amount of time required for them to migrate out of the model is set by the user (no-eat-min). Sharks will migrate back into the model area after a period of time set by the user (return-season). 

<b>Model Versions</b>
The model consists of five submodels, including one Random submodel. The difference between each model version is the behavior and decision making of the sharks within the model. All environmental parameters remain consistent. All model versions, with the exception of Random, begin the same: A shark assesses if the patch it currently resides in contains sufficient zooplankton when divided by the total number of sharks in the patch to meet the threshold zooplankton level set by the user. If the patch contains enough zooplankton, the shark does not move. If the patch contains zooplankton below the minimum threshold, the shark must select a new patch, based on the criteria set in the model version. 

<i>Food Model</i>
In the Food submodels (submodel <b>Memory_shark</b>), the sharks only seek areas that contain zooplankton that exceed the threshold zooplankton (Threshold_zp, set by the user). Each day, a shark will select a patch within its sense-distance that contains enough zooplankton (a combination of both Calanus copepods and other species) to meet the threshold zooplankton level. Out of the list of potential patches, the shark will select the patch with the highest amount of Calanus copepods.  If a shark cannot find a patch that exceeds the threshold zooplankton, it will select a patch based on their own list of patches. Ssharks retain a list of high zooplankton (threshold_zp * 3) patches. If they cannot find a patch with sufficient zooplankton, they will select the closest patch from their memory list. If no patch can be found, the shark swims at random.

<i>Social Model</i>
In the Social Model (submodel <b>Friends</b>), sharks are still urged to move from a patch if there is not sufficient zooplankton. However, they only select a patch based on the number of sharks in the patch (this must be greater than or equal to the friend_min set by the user). It is assumed that sharks can “sense” other sharks from a further distance than zooplankton, due to the significantly larger size of basking sharks and because of the sharks’ slime coat (Lieber et al. 2020), which likely contains sensory information. It is also hypothesized that sharks may be attracted to aggregations via pheromones from other sharks (Sims et al. 2022). Therefore, when seeking other sharks, the sense-distance is set to double. If no patch can be found, the shark swims at random.

<i>Food/social Model</i>
The Food/social Model (model version <b>Both</b>) is a combination of one Food Model (Mem_prob) and the Social Model. In this model version, sharks first search for a patch with zooplankton. If they cannot find one that contains zooplankton above the threshold zooplankton level set by the user, they then search for a patch with other sharks that meet the friend_min (the assumption being either that other sharks indicate food, or perhaps that they desire to mate). If the sharks cannot find a patch with a sufficient amount of other sharks (in sense-distance x 2), they then search for a patch with a probability of zooplankton of 1 (a high probability that zooplankton are still in the patch) (Table 2). If no patch can be found, the shark swims at random. 

<i>Random</i>
Sharks select a random patch to move to. Shark will still complete migration in and out of the model area, based on food availability and the time set in no-eat-min and leave-season (Table 2). 


## HOW TO USE IT

In order: 
1: setup
2: go

<b>Settings</b>

Threshold_zp: Minimum amount of zooplankton (cal and other_zp combined) required for a shark to move to a patch (recommend 3E+12)

No_eat_min: Number of days a shark must encounter a patch that is less than the threshold_zp before leaving the model 	(recommend 14)

Return-season:How many days it will take a shark to return after they have left in response to reaching the no_eat_min (recommend 20)

Sense-distance: How "far" a shark can see (recommend 10)

Cal_%: Percentage of patches with Calanus copepods (recommend 17)

Other_zp_%:Percentage of patches with other large zooplankton	(recommend 17)

Friend_min: Number of other sharks a patch must have to attract a shark (only used in the Social and Food/Social models)	(recommend 5)

Swim-Speed: The distance a shark will swim (in km) (recommend 9)

Total_sharks: maximum number of sharks in the model (Recommend 200)

## THINGS TO NOTICE
Sea Surface Temperature (SST) is included in the model as an input data point, but is not actively used in the model. It can be used for data-analysis.


## THINGS TO TRY



## EXTENDING THE MODEL


## CREDITS AND REFERENCES

Bathymetric map optained from: GEBCO Bathymetric Compilation Group 2020. (2020). The GEBCO_2020 Grid—A continuous terrain model of the global oceans and land. (Version 1) [Network Common Data Form]. British Oceanographic Data Centre, National Oceanography Centre, NERC, UK. https://doi.org/10.5285/A29C5465-B138-234D-E053-6C86ABC040B9

Zooplankton input data comes from zooplankton data supplied by the Continuous Plankton Recorder (https://www.cprsurvey.org).

Get the data used here:
David Johns (Marine Biological Association of the United Kingdom) (2020): CPR_SelectzooUK. The Archive for Marine Species and Habitats Data (DASSH). (Dataset). http://doi.org/10.17031/64d23cc3a1069

Sea Surface Temperature data obtained from: 
European Union-Copernicus Marine Service. (2015). Baltic Sea- Sea Surface Temperature Reprocessed [dataset]. Mercator Ocean International. https://doi.org/10.48670/MOI-00156


Shark travel distances estimated from: Doherty, P. D., Baxter, J. M., Gell, F. R., Godley, B. J., Graham, R. T., Hall, G., Hall, J., Hawkes, L. A., Henderson, S. M., Johnson, L., Speedie, C., & Witt, M. J. (2017). Long-term satellite tracking reveals variable seasonal migration strategies of basking sharks in the north-east Atlantic. Scientific Reports (Nature Publisher Group); London, 7, 42837. http://dx.doi.org/10.1038/srep42837

Shark swimming speed and threshold foraging rates estimated from: Sims, D. W. (2008). Chapter 3 Sieving a Living. In Advances in Marine Biology (Vol. 54, pp. 171–220). Elsevier. https://doi.org/10.1016/S0065-2881(08)00003-5


Data should be compared to shark sightings data from the Irish Basking Shark Group (https://www.baskingshark.ie/)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person student
false
0
Polygon -13791810 true false 135 90 150 105 135 165 150 180 165 165 150 105 165 90
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 100 210 130 225 145 165 85 135 63 189
Polygon -13791810 true false 90 210 120 225 135 165 67 130 53 189
Polygon -1 true false 120 224 131 225 124 210
Line -16777216 false 139 168 126 225
Line -16777216 false 140 167 76 136
Polygon -7500403 true true 105 90 60 195 90 210 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

shark
false
0
Polygon -7500403 true true 283 153 288 149 271 146 301 145 300 138 247 119 190 107 104 117 54 133 39 134 10 99 9 112 19 142 9 175 10 185 40 158 69 154 64 164 80 161 86 156 132 160 209 164
Polygon -7500403 true true 199 161 152 166 137 164 169 154
Polygon -7500403 true true 188 108 172 83 160 74 156 76 159 97 153 112
Circle -16777216 true false 256 129 12
Line -16777216 false 222 134 222 150
Line -16777216 false 217 134 217 150
Line -16777216 false 212 134 212 150
Polygon -7500403 true true 78 125 62 118 63 130
Polygon -7500403 true true 121 157 105 161 101 156 106 152

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="swimspeed8_" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="model-version">
      <value value="&quot;memory_shark&quot;"/>
      <value value="&quot;both&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threshold_zp">
      <value value="100000000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sense-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="swim-speed">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cal_%">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other_zp_%">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="friend_min">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="No_eat_min">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="return-season">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="rerun_testzp" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="model-version">
      <value value="&quot;memory_shark&quot;"/>
      <value value="&quot;both&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threshold_zp">
      <value value="3000000000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sense-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="swim-speed">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cal_%">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other_zp_%">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="friend_min">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="No_eat_min">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="return-season">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="rerun_testzp_cal_otherzp" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="model-version">
      <value value="&quot;memory_shark&quot;"/>
      <value value="&quot;both&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threshold_zp">
      <value value="3000000000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sense-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="swim-speed">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cal_%">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other_zp_%">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="friend_min">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="No_eat_min">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="return-season">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="noeat4_" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="model-version">
      <value value="&quot;memory_shark&quot;"/>
      <value value="&quot;both&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threshold_zp">
      <value value="100000000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sense-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="swim-speed">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cal_%">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other_zp_%">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="friend_min">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="No_eat_min">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="return-season">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="highcal_lowother" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="model-version">
      <value value="&quot;memory_shark&quot;"/>
      <value value="&quot;both&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threshold_zp">
      <value value="3000000000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sense-distance">
      <value value="10"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="swim-speed">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cal_%">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other_zp_%">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="friend_min">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="No_eat_min">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="return-season">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Best_test" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="model-version">
      <value value="&quot;memory_shark&quot;"/>
      <value value="&quot;both&quot;"/>
      <value value="&quot;random&quot;"/>
      <value value="&quot;friends&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threshold_zp">
      <value value="3000000000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sense-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="swim-speed">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cal_%">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other_zp_%">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="friend_min">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="No_eat_min">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="return-season">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_sharks">
      <value value="100"/>
      <value value="200"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="second best" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="model-version">
      <value value="&quot;memory_shark&quot;"/>
      <value value="&quot;both&quot;"/>
      <value value="&quot;random&quot;"/>
      <value value="&quot;friends&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threshold_zp">
      <value value="3000000000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sense-distance">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="swim-speed">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cal_%">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other_zp_%">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="friend_min">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="No_eat_min">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="return-season">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_sharks">
      <value value="100"/>
      <value value="200"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Threshold June 2025 SA RA" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="threshold_zp">
      <value value="3000000000000"/>
      <value value="3150000000000"/>
      <value value="2850000000000"/>
      <value value="5100000000000"/>
      <value value="900000000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sense-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="swim-speed">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cal_%">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other_zp_%">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="friend_min">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="No_eat_min">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="return-season">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_sharks">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="model-version">
      <value value="&quot;both&quot;"/>
      <value value="&quot;memory_shark&quot;"/>
      <value value="&quot;friends&quot;"/>
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Sense Distance June 2025 SA RA" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="threshold_zp">
      <value value="3000000000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sense-distance">
      <value value="11"/>
      <value value="9"/>
      <value value="17"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="swim-speed">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cal_%">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other_zp_%">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="friend_min">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="No_eat_min">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="return-season">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_sharks">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="model-version">
      <value value="&quot;both&quot;"/>
      <value value="&quot;memory_shark&quot;"/>
      <value value="&quot;friends&quot;"/>
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Swim Speend June 2025 SA RA" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="threshold_zp">
      <value value="3000000000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sense-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="swim-speed">
      <value value="10"/>
      <value value="8"/>
      <value value="15"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cal_%">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other_zp_%">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="friend_min">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="No_eat_min">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="return-season">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_sharks">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="model-version">
      <value value="&quot;both&quot;"/>
      <value value="&quot;memory_shark&quot;"/>
      <value value="&quot;friends&quot;"/>
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Cal June 2025 SA RA" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="threshold_zp">
      <value value="3000000000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sense-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="swim-speed">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cal_%">
      <value value="18"/>
      <value value="16"/>
      <value value="29"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other_zp_%">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="friend_min">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="No_eat_min">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="return-season">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_sharks">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="model-version">
      <value value="&quot;both&quot;"/>
      <value value="&quot;memory_shark&quot;"/>
      <value value="&quot;friends&quot;"/>
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="OtherZP June 2025 SA RA" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="threshold_zp">
      <value value="3000000000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sense-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="swim-speed">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cal_%">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other_zp_%">
      <value value="18"/>
      <value value="16"/>
      <value value="29"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="friend_min">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="No_eat_min">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="return-season">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_sharks">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="model-version">
      <value value="&quot;both&quot;"/>
      <value value="&quot;memory_shark&quot;"/>
      <value value="&quot;friends&quot;"/>
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Friend min June 2025 SA RA" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="sense-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="swim-speed">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cal_%">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other_zp_%">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="friend_min">
      <value value="6"/>
      <value value="4"/>
      <value value="9"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="No_eat_min">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="return-season">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_sharks">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="model-version">
      <value value="&quot;both&quot;"/>
      <value value="&quot;memory_shark&quot;"/>
      <value value="&quot;friends&quot;"/>
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="noeat min June 2025 SA RA" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="sense-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="swim-speed">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cal_%">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other_zp_%">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="friend_min">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="No_eat_min">
      <value value="15"/>
      <value value="13"/>
      <value value="24"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="return-season">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_sharks">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="model-version">
      <value value="&quot;both&quot;"/>
      <value value="&quot;memory_shark&quot;"/>
      <value value="&quot;friends&quot;"/>
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="returnseason  June 2025 SA RA" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="sense-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="swim-speed">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cal_%">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other_zp_%">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="friend_min">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="No_eat_min">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="return-season">
      <value value="21"/>
      <value value="19"/>
      <value value="34"/>
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_sharks">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="model-version">
      <value value="&quot;both&quot;"/>
      <value value="&quot;memory_shark&quot;"/>
      <value value="&quot;friends&quot;"/>
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
