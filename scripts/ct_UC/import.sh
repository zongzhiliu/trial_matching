# the workflow to create and populate ct_${cancer} schema
# requires:
# ct.py_contains, .ref_drug_mapping .ref_lab_mapping
# ct.ref_proc_mapping, ct.ref_rx_mapping
source ct_UC/config.sh
source ct_CD/import_ibd.sh
