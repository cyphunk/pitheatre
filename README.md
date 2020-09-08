# Pi Theatre

After using the Raspberry Pi for many years to develop prototypes for use in performance and theatre projects I've come to extensively depend on these custom snippits and RPi image creation tools. They should work on Linux or OSX to create RPi SD card images. Of interest most is probably the `startup.sh` script and the various `snippet` scripts found in the `home/pi` directory. The scripts are written to place control and configuration within one central location rather than editing files all across the system. For example the wifi is configured by `startup.sh` and within that single script rather than pointing users to where to effect the wifi configuration on the system files.

These tools were developed over time and while using them in Johannes Paul Raether's "Protektorame" performances and installations, Jaha Koo's "Cuckoo" & "The History of Korean Western Theatre", Ogutu Muraya's "[Because I Always Feel Like Running](https://github.com/cyphunk/because_i_always_feel_like_running)", the "[Counter](https://github.com/cyphunk/counter)" for Harriet Rabe, the [Shrine](https://github.com/cyphunk/shrine) for Frank & Robbert and various other projects.

## Use

* [Download a Raspberry Pi OS image](https://www.raspberrypi.org/downloads/) into this repositories directory (next to make_image.sh)
* If you intend to use `startup.sh` to initialize network and wifi you may want to examine that script.
* If you want your ssh keys copied over when the OS image is dd'ed to the SD card you might include those in the `home/pi/.ssh` directory and `root/.ssh` directory already
* run `make_image.sh`

Optionally you can try to pre-download packages you will need for your project using the `download_packages.sh`. Review the script for use instructions.
