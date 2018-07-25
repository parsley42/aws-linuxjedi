# data_vol_single

The `data_vol_single` role is used for setting up a single, persistent, monolithic data volume, where all mountpoints are `bind` mounted from `/data/<dirname>`.

`data_vol_single` expects a `mount_points` array of `dir_name` and `mount_point` pairs, like so:

```yaml
mount_points:
- dir_name: home
  mount_point: /home
- dir_name: local
  mount_point: /usr/local
- dir_name: www
  mount_point: /var/www
```

This can be done with `set_fact` in a playbook for building a specific type of host, or in `host_vars`.
