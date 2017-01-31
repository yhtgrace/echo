
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
    
    // parameters for the optimal amount of fluids
    real gamma_bias;
    vector[5] gamma_ea_lv_systolic;
    real gamma_ex_congestive_heart_failure;
    real gamma_mech_vent;
    real gamma_mdrd;
    vector[5] gamma_lv_sys_by_chf;
    vector[5] gamma_lv_sys_by_mdrd;
    
    // parameters for the penalty for moving away from the optimal
    // amound of fluids
    real theta_bias;
    vector[5] theta_ea_lv_systolic;
    real theta_ex_congestive_heart_failure;
    real theta_mech_vent;
    real theta_mdrd;
    vector[5] theta_lv_sys_by_chf;
    vector[5] theta_lv_sys_by_mdrd;
    
}

transformed parameters {
    // ylogit = beta + theta*(fluids - gamma)^2
        
    vector[N] y_hat;
    vector[N] beta;
    vector[N] gamma;    
    vector[N] theta;
    
    beta = bias + beta_ea_lv_systolic[ea_lv_systolic]
        + beta_ex_congestive_heart_failure * ex_congestive_heart_failure
        + beta_mech_vent*mech_vent
        + beta_mdrd*mdrd
        + beta_apsiii*apsiii
        + beta_age*age;
    
    gamma = gamma_bias + gamma_ea_lv_systolic[ea_lv_systolic]
        + gamma_ex_congestive_heart_failure*ex_congestive_heart_failure
        + gamma_mech_vent*mech_vent
        + gamma_mdrd*mdrd
        + gamma_lv_sys_by_chf[ea_lv_systolic] .* ex_congestive_heart_failure
        + gamma_lv_sys_by_mdrd[ea_lv_systolic] .* mdrd;

    theta = theta_bias + theta_ea_lv_systolic[ea_lv_systolic]
        + theta_ex_congestive_heart_failure*ex_congestive_heart_failure
        + theta_mech_vent*mech_vent
        + theta_mdrd*mdrd
        + theta_lv_sys_by_chf[ea_lv_systolic] .* ex_congestive_heart_failure
        + theta_lv_sys_by_mdrd[ea_lv_systolic] .* mdrd;
    // theta should not be less than 0
    theta = exp(theta);
    //for (i in 1:N){
    //    if (theta[i] < 0){
    //        theta[i] = 0;
    //    }
    //}

    y_hat = beta + theta .* square(fluid_day1_balance - gamma);
    
}

model {
    beta_ea_lv_systolic ~ normal(0,1);
    beta_ex_congestive_heart_failure ~ normal(0,1);
    beta_mech_vent ~ normal(0,1);
    beta_mdrd ~ normal(0,1);
    beta_apsiii ~ normal(0,1);
    beta_age ~ normal(0,1);
    
    gamma_bias ~ normal(0,10);
    gamma_ea_lv_systolic ~ normal(0,1);
    gamma_ex_congestive_heart_failure ~ normal(0,1);
    gamma_mech_vent ~ normal(0,1);
    gamma_mdrd ~ normal(0,1);
    gamma_lv_sys_by_chf ~ normal(0,1);
    gamma_lv_sys_by_mdrd ~ normal(0,1);
    
    theta_bias ~ normal(-5,10);
    theta_ea_lv_systolic ~ normal(0,1);
    theta_ex_congestive_heart_failure ~ normal(0,1);
    theta_mech_vent ~ normal(0,1);
    theta_mdrd ~ normal(0,1);
    theta_lv_sys_by_chf ~ normal(0,1);
    theta_lv_sys_by_mdrd ~ normal(0,1);
    
    y ~ bernoulli_logit(y_hat);
}
