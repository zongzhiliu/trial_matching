# Readme

## log
```
* 20200401 add a line protocol_date=$(date +%Y-%m-%d) in each config file
* 20200401 change all current_date into ${protocol_date} in the sql files
    bufdo %s/current_date/'${protocal_date}'/ge | update
```
