# esx_convoyeurjob

## Requirements

- [cron](https://github.com/ESX-Org/cron)
- [esx_addonaccount](https://github.com/ESX-Org/esx_addonaccount)
- [esx_addoninventory](https://github.com/ESX-Org/esx_addoninventory)
- [esx_datastore](https://github.com/ESX-Org/esx_datastore)
- [esx_society](https://github.com/ESX-Org/esx_society)

## Download & Installation

### Using [fvm](https://github.com/qlaffont/fvm-installer)
```
fvm install --save --folder=esx esx-org/esx_convoyeurjob
```

### Using Git
```
cd resources
git clone https://github.com/Michael75013/esx_Convoyeurjob [esx]/esx_convoyeurjob
```

## Installation
- Import `esx_convoyeurjob.sql` in your database
- Add this in your `server.cfg`:

```
start esx_convoyeurjob
```
