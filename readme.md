# Team O

captain teemo on duty 

## Building the features table

#### First build the echodata and ventdurations tables using scripts from the mimic-code repository
```
src/Makefile mimic-code/etc/echodata
src/Makefile mimic-code/etc/ventilation-durations
src/Makefile mimic-code/severityscores/apsiii
src/Makefile mimic-code/comorbidity/elixhauser-ahrq-v37-with-drg.sql
```

#### Build the individual echo features tables

##### Match echos with ICU stays
```
src/Makefile src/echo_icustay
```

##### Load the excluded diagnoses from CSV file in resources
```
src/Makefile src/d_diagnoses_xc_annot
```

##### Build table of prescriptions that are considered vasopressors
```
src/Makefile src/d_prescriptions_vaso
```

##### Get the outpatient echos
```
src/Makefile src/echo_outpatient
```

##### Calculate variables associated with inclusion/exclusion criteria
```
src/Makefile src/echo_filter_vars
```

##### Calculate lab value features
```
src/Makefile src/echo_features_labs
```

##### Calculate ventilator features
```
src/Makefile src/venttype
src/Makefile src/ventfeatures
```

#### Calculate if patient is on chronic dialysis 
```
src/Makefile src/chronic_dialysis
```

#### Load echo annotations
```
src/Makefile src/

#### Build the master features table
```
src/Makefile src/echo_features
```





