# airdrop-cli

A command-line tool that allows you to share files and URLs with Apple
devices using AirDrop from your terminal.

## Prerequisities
- Xcode
- Xcode Command Line Tools

## Installation

`airdrop-cli` is available for install with [Homebrew](https://brew.sh/)

```
brew install vldmrkl/formulae/airdrop-cli
```

or

```
brew tap vldmrkl/formulae
brew install airdrop-cli
```

### Building from source

Before attempting to build this project from its source code, make sure
that you have Xcode version 11.4 (or higher) & GNU `make` installed.

Then, clone the project and use the Makefile

```
git clone https://github.com/vldmrkl/airdrop-cli.git
cd airdrop-cli
make
sudo make install
```

By default, make will build and install the project within
`/usr/local/bin`. This project location can be changed by appending
a new prefix to the `PREFIX` variable.

```
make PREFIX="YOUR_PREFIX_HERE"
```

You can append other Swift flags, in case you may need them for your
specific build, to the `FLAGS` variable.

## Usage

![airdrop-cli-demo](https://user-images.githubusercontent.com/26641473/103395121-762ef380-4afa-11eb-9bc8-6cf6068edf32.gif)

### Basic Usage

To airdrop files, run:

```bash
airdrop /path/to/your/file
```

You can also airdrop URLs:

```bash
airdrop https://apple.com/
```

You can pass as many paths as you want. As long as these file URLs are correct,
the command will work.

### Recipient Aliases

You can now manage recipient aliases to remember who you frequently share with:

**Add an alias:**
```bash
airdrop --add-alias ben "Ben's MacBook Pro"
airdrop --add-alias sarah
```

**List your aliases:**
```bash
airdrop --list-aliases
```

**Use an alias when sharing:**
```bash
airdrop --recipient ben document.pdf
airdrop -r sarah photo.jpg video.mov
```

**Remove an alias:**
```bash
airdrop --remove-alias ben
```

The recipient alias feature helps you keep track of who you're sending to. The alias information is stored locally in `~/.airdrop-cli-aliases.json`.

> **Note**: Due to macOS privacy and security restrictions, the AirDrop picker UI will still appear when sharing files. The alias system helps you remember recipient names for your records, but macOS requires user interaction to select the final recipient for AirDrop transfers.

### Advanced Usage

**Pipe files from other commands:**
```bash
find . -name '*.pdf' | airdrop -
```

**Mix files and URLs:**
```bash
airdrop document.pdf https://apple.com/ photo.jpg
```

### Options

- `-h, --help` - Print help information
- `-r, --recipient NAME` - Specify recipient alias (for your records)
- `--list-aliases` - List all configured recipient aliases
- `--add-alias NAME [DESCRIPTION]` - Add a new recipient alias
- `--remove-alias NAME` - Remove a recipient alias
- `-` - Read file paths from stdin
