# Setting up import.sh on Mac.

## Requirements:
* Python3.7
* ipython
* psql
* pip
* git
* Several python package:
 * pandas
 * pytest

## Steps:
### Step 1: Install s4-radbinf-db-tools
1. Go to the directory that you wish to keep the folder and run: `git clone https://github.com/sema4genomics/s4-radbinf-db-tools.git`
2. run `cd s4-radbinf-db-tools`
3. `pip install .`

### Step 2: Edit Bash Profile
1. Change to home directory: `cd $home`
2. Use your prefered ide to edit the *.bash_profile* profile. `vim .bash_file`
3. Copy and paste the folloing code into the bash profile, remember to change *username* into actual username
```bash
# rdmsdw
export rdmsdw_host='s4-dmsdw.cswcn2wwxepe.us-east-1.redshift.amazonaws.com'
export rdmsdw_bastion='ec2-3-214-186-216.compute-1.amazonaws.com'
# rimsdw
export rimsdw_host='auto-abst-redshift-cluster.cpgxfro2regq.us-east-1.redshift.amazonaws.com'
export rimsdw_bastion='auto-abst-bastion-host-lb-542f9513ec56d4ad.elb.us-east-1.amazonaws.com'
# pharma
export pharma_host=mvppharmainstance.cluster-cxk2gapy925c.us-east-1.rds.amazonaws.com

function start_ssh_tunnel {
    tunnel_name=$1; shift
    lport_dhost_rport=$1; shift
    user_at_remote=$1; shift
    other_args=$@
    cmd="AUTOSSH_DEBUG=1 autossh -g -M 0 -N -L $lport_dhost_rport $user_at_remote $other_args \
            -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -o ServerAliveInterval=10 -o ServerAliveCountMax=1 \
            -o ExitOnForwardFailure=yes -o ControlMaster=no -o ControlPath=/dev/null"
    if ! screen -ls | grep -q "[0-9]\+.$tunnel_name\s"; then
        screen -S "$tunnel_name" -dm bash -c "$cmd"
    fi
}
function start_all_port_forwarding {
    start_ssh_tunnel rdmsdw 9998:$rdmsdw_host:5439 {user_name}@$rdmsdw_bastion
    start_ssh_tunnel rimsdw 9999:$rimsdw_host:5439 {user_name}@$rimsdw_bastion
    start_ssh_tunnel pharma 3308:$pharma_host:3306 ec2-user@3.214.48.87 \
        -i $HOME/.ssh/mvp-pharma.pem
}
# screen -ls | grep Detached | cut -d. -f1 | xargs kill
# set up for postgre connection using PGPASSFILE
# usage: pgsetup rdmsdw
function pgsetup {
    export PGPASSFILE="$HOME/.pgpass_${1}"
    IFS=':' read PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD <<<$(head -1 ${PGPASSFILE})
    export PGHOST; export PGPORT; export PGDATABASE; export PGUSER # Need to export for psql
    export PGPASSWORD  # Let's just use the pgpass file instead case someone does `env`
 
    export PSQL="psql --echo-all --no-psqlrc -v ON_ERROR_STOP=1"
}
```
4. Safe your changes and run `source .bash_profile`

### Step 3: Prepare for the pgpass file 
1. Create file `.pgpass_rdmsdw`, `.pgpass_rimsdw`
2. In each file, add following code:
```
127.0.0.1:9998:{database_name}:{user_name}:{yourpassword}
```
3. Run `source {filename}`
### Step 4: Setup ipython
1. Edit file: `vim ~/.ipython/profile_default/startup/00_first.py`
2. Add following code:
```python
import sys, os, pathlib, io, csv, re, datetime, random
import warnings, logging, argparse
import typing, collections, itertools, functools
import subprocess as sp, importlib as imp
import numpy as np, pandas as pd
import pytest
```

