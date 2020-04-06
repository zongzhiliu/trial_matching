/* generating a 1% subset of the dmsdw database
Require: dmsdw_2019q1
Results: dmsdw_testing
Algorithm:
    * gen a random 1% of cohort by mrn
    * filter by mrn
        d_person, d_encounter, d_demographics
    * filter by person_key
        fact, fact_lab, fact_eagle
    * filter by {}_group_key
        b_... tables
    * cp the full tables
        fd_... tables
        d_metadata, d_unit_of_measure, d_data_state
        d_time_of_day, d_calendar
*/


