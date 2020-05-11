select ct.py_contains('C34.1', (select icd_10 from ct.ref_cancer_icd where cancer_type_name='LCA'));
