# the workflow to create and populate ct_UC_testing schema
# requires:
# ct.py_contains, .ref_drug_mapping .ref_lab_mapping
# ct.ref_proc_mapping, ct.ref_rx_mapping
source ct_UC_testing/config.sh
cd $working_dir
ln -sf $PWD/../ct_CD/trial_info.csv .
ln -sf $PWD/../ct_CD/crit_attribute_raw_.csv .
ln -sf $PWD/../ct_CD/trial_attribute_raw_.csv .
cd -

source ct_CD/import_ibd.sh
