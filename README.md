NK bot
=================
Very simple bot to invite people

Configuration
------------
Copy `configuration.template` to `configuration`
The most important think is to configure `USER`, `PASSWORD` and `MAX_ID` after all set `LAST_ID`

Filters
------------
Directory `filters` has few default filters. You can simple add new filter, write code, put it into directory `filters` and set permission `chmod +x filters/super_filter.filter`. If you want shutdown one of filter just change extension eg. `mv filters/xxx.filter filters/xxx.filter.disabled`. 

Usage
------------
run `./profileInviter` to invite people from the scope of the `LAST_ID` `MAX_ID`
