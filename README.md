[README.md](https://github.com/user-attachments/files/31949507/README.md)
# Twitcher

A Garmin Connect IQ widget that shows recent bird sightings near your location.

Twitcher reads your watch's GPS position and asks eBird what has been reported nearby in the last week. It shows a short list of species, with a crude silhouette for each so you can tell a gull from a wader at a glance. There is a second section for anything locally unusual, which in practice tends to surface passage migrants.

It does not identify birds. It has no photos, no sound recognition, and no idea what you are actually looking at. It tells you what other people have seen near where you are standing, which is sometimes enough to narrow things down.

## Screenshot

<img width="562" height="563" alt="Screenshot" src="https://github.com/user-attachments/assets/f7bed1a8-9e31-4c7c-812d-e44fd8acb375" />

## Requirements

- A Garmin watch running Connect IQ 3.0 or later, roughly anything from 2019 onwards
- A phone paired via Garmin Connect, since most watches have no internet connection of their own
- A free eBird API key (see below)

## Getting an eBird API key

Twitcher does not ship with an API key. Each user supplies their own, so that usage is attributed correctly and no single key carries the load for everyone.

1. Create a free account at [ebird.org](https://ebird.org) if you do not have one
2. Go to [ebird.org/api/keygen](https://ebird.org/api/keygen)
3. Fill in the short form. For project type choose **General**, and for use case tick **Personal use**
4. Copy the key you are given
5. In the Connect IQ app on your phone, open Twitcher's settings and paste the key in

Keys are usually issued immediately.

## Settings

| Setting | Default | Range |
| --- | --- | --- |
| eBird API key | empty | required |
| Search radius | 15 km | 1–50 |
| Days to look back | 7 | 1–30 |

## Using it

Open Twitcher from the glance loop or the apps list.

- **UP / DOWN** scrolls the list
- **START** forces a refresh, including a new GPS fix

The first load needs a GPS position, so it may take a few seconds outdoors and considerably longer indoors. If the watch cannot get a fix it will retry for about a minute and then stop, at which point pressing START tries again.

## Known limitations

The species silhouettes are matched on keywords in the common name, so they are approximate and occasionally wrong. Anything unrecognised gets a generic bird. The keyword lists cover Britain, North America and Australia reasonably well and are thinner elsewhere. Additions are welcome.

Only confirmed sightings are shown, which means recent records awaiting review are filtered out. This makes the list shorter but more trustworthy.

Watches limit how large an API response can be, so the list is capped well below what eBird would return.

## Building from source

You will need the [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) and the Monkey C extension for VS Code.

```
git clone https://github.com/YOURNAME/twitcher.git
```

Open the folder in VS Code, then use `Monkey C: Build for Device` or press F5 to run in the simulator.

To test on a real watch, copy `bin/Twitcher.prg` to `GARMIN/APPS` on the device. On macOS you will need something like [OpenMTP](https://openmtp.ganeshrvel.com) to browse the watch, since macOS does not support MTP natively. Sideloaded apps have no settings screen, so put your API key in `resources/settings/properties.xml` as the default value for local testing.

## Data and privacy

Twitcher collects nothing, stores nothing about you, and sends nothing anywhere except eBird. Requests contain your coordinates, rounded to four decimal places, and your own API key. There is no analytics, no account, and no server in between.

## Credits

Bird observation data comes from [eBird](https://ebird.org), run by the Cornell Lab of Ornithology. eBird's data is contributed by tens of thousands of volunteer birdwatchers. If you find this useful, consider [submitting your own checklists](https://ebird.org/submit).

## Licence

MIT
