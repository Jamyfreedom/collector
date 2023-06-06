# NIX Triage

## Supported OSes

All supported OS and planned future supports

- [x] Debian 8, Ubuntu 16.04 or earlier and their derivatives
- [x] Debian 9, Ubuntu 18.04 or later and their derivatives
- [x] RHEL/CentOS 6 or earlier and their derivatives
- [x] RHEL/CentOS 7 or later and their derivatives
- [ ] SLES 11 or earlier
- [ ] SLES 12 or later
- [ ] Solaris 10
- [x] Solaris 11
- [ ] AIX 6
- [ ] AIX 7.1
- [ ] AIX 7.2

## Running the script

There are three ways to start triage data collection

### 1. `main.sh` on Autopilot mode

- `main.sh` is written such that it will be able to attempt to detect the operating system family and version that it is running on and subsequently construct the correct arguments to run `collector.sh`.
- Running `main.sh` with `-a` is sufficient to run the whole collection on the machine on Autopilot mode.

```bash
user@machine:~$ sudo sh main.sh -a
# Starts in Autopilot mode
```

### 2. `main.sh` on Interactive mode

- `main.sh` can also run such that all inputs are taken in from the user. This includes OS family and version numbers.
- Running `main.sh` with no arguments will start in interactive mode, prompting the user for answers.

```bash
user@machine:~$ sudo sh main.sh
# Answer questions accordingly. Incomplete for now, does nothing.
```

### 3. Running `collector.sh` with  command line arguments

- `collector.sh` needs to be run with arguments.  
- Output directories can be specified using `-d` or `-o`. But only one of those flags can be specified, if both are specified the script fails.
  - `-d` sets output to current working directory
  - `-o` sets output to whichever path in the following string
- Operating system type must be specified using `-n`. use `-n list` to show available operating systems

```bash
# Ex 1, place output in current directory, RHEL 7 system
user@machine:~/nix-triage$ sudo sh collector.sh -d -n rhel7
# Ex 2, place output in /tmp/output/, Ubuntu 20.04 LTS
user@machine:~/nix-triage$ sudo sh collector.sh -o /tmp/output -n ubuntu18
# Ex 3, view all supported operating systems
user@machine:~/nix-triage$ sudo sh collector.sh -n list
```

## Help Texts

### `main.sh`

```bash
Usage: main.sh [-h] [-a]

Options:
    -h    Show this help message
    -a    Run on autopilot mode

Autopilot: Attempts to automatically pass arguments based on
           available files in /etc. Also saves output to home
           directory of the current user
Interactive mode is currently incomplete. Functionally does nothing.
```

### `collector.sh`

```bash
Usage: collector.sh [-h] [-d|-o <outdir>] -n <os>

Options:
    -h            Show this help message
    -o <outdir>   Set output directory of this script to <outdir>
    -d            Set output directory to same directory as script
    -n <os>       Run script for <os>. '-n list' to show supported

-n must be specified
One of -o or -d must be provided
But only one of -o and -d can be specified at once
```

## Licenses and Attribution

All source codes may be made available upon request and further discussion. All License texts are available in files named `<software-name>.LICENSE` in the same directory as the executables.

1. `chkrootkit`: Free Software, Pangeia Informatica
2. `tsk/`:
   - `fls`: Common Public License 1.0
   - `ils`: IBM Public License 1.0
   - `mac-robber`: GNU General Public License v2
3. `vuls`: GNU Affero General Public License v3
