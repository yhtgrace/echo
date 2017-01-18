
data{
    int<lower=0> N;
    
    int<lower=1, upper=5> ea_lv_systolic[N];
    //int<lower=0, upper=1> ex_congestive_heart_failure[N];
    //int<lower=0, upper=1> mech_vent[N];
    vector[N] ex_congestive_heart_failure;
    vector[N] mech_vent;
    vector[N] mdrd;
    vector[N] apsiii;
    vector[N] age;
    vector[N] fluid_day1_balance;
    
    int<lower=0, upper=1> y[N];
}

parameters{
    real bias;
    
    vector[5] beta_ea_lv_systolic;
    real beta_ex_congestive_heart_failure;
    real beta_mech_vent;
    real beta_mdrd;
    real beta_apsiii;
    real beta_age;
    real beta_fluid;
    
    vector[5] gamma_ea_lv_systolic;
    real gamma_ex_congestive_heart_failure;
    real gamma_mech_vent;
    real gamma_mdrd;
    
    vector[5] gamma_lv_sys_by_chf;
    vector[5] gamma_lv_sys_by_mdrd;
    
    real beta2_fluid;
    
    vector[5] gamma2_ea_lv_systolic;
    real gamma2_ex_congestive_heart_failure;
    real gamma2_mech_vent;
    real gamma2_mdrd;
    
    vector[5] gamma2_lv_sys_by_chf;
    vector[5] gamma2_lv_sys_by_mdrd;
    
}

transformed parameters {
    vector[N] y_hat;
    y_hat = bias
       + beta_ea_lv_systolic[ea_lv_systolic]
       + beta_ex_congestive_heart_failure * ex_congestive_heart_failure
       + beta_mech_vent*mech_vent
       + beta_mdrd*mdrd
       + beta_apsiii*apsiii
       + beta_age*age
       + fluid_day1_balance .* (beta_fluid
          + gamma_ea_lv_systolic[ea_lv_systolic]
          + gamma_ex_congestive_heart_failure*ex_congestive_heart_failure
          + gamma_mech_vent*mech_vent
          + gamma_mdrd*mdrd
          + gamma_lv_sys_by_chf[ea_lv_systolic] .* ex_congestive_heart_failure
          + gamma_lv_sys_by_mdrd[ea_lv_systolic] .* mdrd)
       + fluid_day1_balance .* fluid_day1_balance .* (beta2_fluid
          + gamma2_ea_lv_systolic[ea_lv_systolic]
          + gamma2_ex_congestive_heart_failure*ex_congestive_heart_failure
          + gamma2_mech_vent*mech_vent
          + gamma2_mdrd*mdrd
          + gamma2_lv_sys_by_chf[ea_lv_systolic] .* ex_congestive_heart_failure
          + gamma2_lv_sys_by_mdrd[ea_lv_systolic] .* mdrd);
    
}

model {
    beta_ea_lv_systolic ~ normal(0,1);
    beta_ex_congestive_heart_failure ~ normal(0,1);
    beta_mech_vent ~ normal(0,1);
    beta_mdrd ~ normal(0,1);
    beta_apsiii ~ normal(0,1);
    beta_age ~ normal(0,1);
    beta_fluid ~ normal(0,1);
    gamma_ea_lv_systolic ~ normal(0,1);
    gamma_ex_congestive_heart_failure ~ normal(0,1);
    gamma_mech_vent ~ normal(0,1);
    gamma_mdrd ~ normal(0,1);
    gamma_lv_sys_by_chf ~ normal(0,1);
    gamma_lv_sys_by_mdrd ~ normal(0,1);
    beta2_fluid ~ normal(0,1);
    gamma2_ea_lv_systolic ~ normal(0,1);
    gamma2_ex_congestive_heart_failure ~ normal(0,1);
    gamma2_mech_vent ~ normal(0,1);
    gamma2_mdrd ~ normal(0,1);
    gamma2_lv_sys_by_chf ~ normal(0,1);
    gamma2_lv_sys_by_mdrd ~ normal(0,1);
    
    y ~ bernoulli_logit(y_hat);
}

generated quantities{
    

}
